DELIMITER //
DROP PROCEDURE IF EXISTS spBillingUpdateAttendanceBilling //
CREATE PROCEDURE spBillingUpdateAttendanceBilling(paramBillingStartDate date, paramCreatedBy varchar(45),  paramContactId int)
BEGIN
    DECLARE paramSmGroupPercent DECIMAL(5,3);
	DECLARE paramInterGroupPercent DECIMAL(5,3);
	DECLARE paramLargeGroupPercent DECIMAL(5,3);
	DECLARE paramCMPercent DECIMAL(5,3);
    DECLARE paramMaxDaysPerBillingPeriod INT;
    
	SELECT MaxBillableDaysPerBillingPeriod
	INTO paramMaxDaysPerBillingPeriod
    FROM billingCycle
    WHERE billingStartDate = paramBillingStartDate
		and billingType = 'Attendance';
    
    SET paramSmGroupPercent = 0.333,
		paramInterGroupPercent = 0.222,
		paramLargeGroupPercent = 0.167,
		paramCMPercent = 0.167;  # CM is 0.167 * 10% of the eligible CM hours
        
	DROP TEMPORARY TABLE IF EXISTS sptmp_billingStudentItem;
	CREATE TEMPORARY TABLE sptmp_billingStudentItem AS
   	select bsc.billingScenarioName,
		bsc.IndPercent,
		bsc.SmallPercent,
		bsc.InterPercent,
		bsc.LargePercent,
        bsi.BillingStudentItemID
	from billingStudentItem bsi
		join billingStudent bs on bs.BillingStudentID = bsi.BillingStudentID
		join billingScenarioByCourse bsbc  on bsi.CRN = bsbc.CRN and bs.term = bsbc.term
		join billingScenario bsc on bsbc.billingScenarioId = bsc.billingScenarioId
		join keySchoolDistrict sd on bs.DistrictID = sd.keySchoolDistrictID
	where bsi.includeFlag = 1
		and bs.Program like '%attendance%'
		and bs.billingStartDate = paramBillingStartDate
        and (bs.contactId = paramContactId or paramContactId = 0);    
        
	#best to just update when there is a change, keeps the 
    #dateLastUpdated current to see when really a last change
	update billingStudentItem bsi
		join sptmp_billingStudentItem tmp on bsi.BillingStudentItemID = tmp.BillingStudentItemID
	set bsi.Scenario = tmp.billingScenarioName,
		bsi.IndPercent = tmp.IndPercent,
		bsi.SmallPercent = tmp.SmallPercent,
		bsi.InterPercent = tmp.InterPercent,
		bsi.LargePercent = tmp.LargePercent,
        bsi.DateLastUpdated = now(),
        bsi.LastUpdatedBy = paramCreatedBy
	where (bsi.Scenario <> tmp.billingScenarioName or bsi.Scenario is null)
		or bsi.IndPercent <> tmp.IndPercent
		or bsi.SmallPercent <> tmp.SmallPercent
		or bsi.InterPercent <> tmp.InterPercent
		or bsi.LargePercent <> tmp.LargePercent;
        
	/*going to do some stepped updates to help with calculations of max days per month
			   where a month is split between two terms.  In that instance, the later billing start date
			   for the month will have the aggregated number of days between the two terms, and contain
			   the amount billed for the month   */
	update billingStudent
	set maxDaysPerBillingPeriod = paramMaxDaysPerBillingPeriod,
        DateLastUpdated = now(),
        LastUpdatedBy = paramCreatedBy
	where Program like '%attendance%'
		and billingStartDate = paramBillingStartDate
        and (contactId = paramContactId or paramContactId = 0)
        and (maxDaysPerBillingPeriod <> paramMaxDaysPerBillingPeriod or  maxDaysPerBillingPeriod is null);
            
	#updateMaxDaysPerMonth
	update billingStudent
		join (select contactId, max(billingStartDate) billingStartDate, sum(maxDaysPerBillingPeriod) maxDaysPerMonth
			  from billingStudent bsSub
			  where bsSub.Program like '%attendance%'
					and MONTH(bsSub.billingStartDate) = MONTH(paramBillingStartDate)
					and YEAR(bsSub.billingStartDate) = YEAR(paramBillingStartDate)
                    and (bsSub.contactId = paramContactId or paramContactId = 0)
			  group by contactId
			) bsMonth on billingStudent.contactId = bsMonth.contactId
				and billingStudent.billingStartDate = bsMonth.billingStartDate
	set billingStudent.maxDaysPerMonth = bsMonth.maxDaysPerMonth,
		billingStudent.DateLastUpdated = now(),
        billingStudent.LastUpdatedBy = paramCreatedBy
	where (billingStudent.maxDaysPerMonth <> bsMonth.maxDaysPerMonth or billingStudent.maxDaysPerMonth is null);

	DROP TEMPORARY TABLE IF EXISTS sptmp_billingStudent;
	CREATE TEMPORARY TABLE sptmp_billingStudent AS
	select billingStudentId
		,maxDaysPerMonth
        ,AdjustedDaysPerMonth
		,sum(ind) + sum(small)*paramSmGroupPercent + sum(inter)*paramInterGroupPercent + sum(large)*paramLargeGroupPercent 
			+ sum(ind+small+inter+large)*0.10*paramCMPercent BilledAmount
		,sum(small) Small, sum(inter) Inter, sum(Large) Large
	from (
		select bs.billingStudentId, bs.maxDaysPerMonth, bs.AdjustedDaysPerMonth
			,bsi.Attendance*IFNULL(IndPercent,0) as Ind
			,bsi.Attendance*IFNULL(SmallPercent,0) as Small
			,bsi.Attendance*IFNULL(InterPercent,0) as Inter
			,bsi.Attendance*IFNULL(LargePercent,0) as Large
		from billingStudent bs
			join billingStudentItem bsi on bs.BillingStudentID = bsi.BillingStudentID
			join keySchoolDistrict sd on bs.DistrictID = sd.keySchoolDistrictID
		where bsi.includeFlag = 1
			and bs.Program like '%attendance%'
			and bs.billingStartDate = paramBillingStartDate
            and (bs.contactId = paramContactId or paramContactId = 0)
			) data
	group by billingStudentId, maxDaysPerMonth;

    
    #updateWithMonthMaxDaysPerMonth
	update billingStudent
		join (	select billingStudentId
					, round(IFNULL(case when BilledAmount > IFNULL(AdjustedDaysPerMonth, maxDaysPerMonth)
													then IFNULL(AdjustedDaysPerMonth, maxDaysPerMonth)
													else BilledAmount end,0),2) GeneratedBilledAmount
					, round(IFNULL(case when BilledAmount > IFNULL(AdjustedDaysPerMonth, maxDaysPerMonth)
													 then BilledAmount - IFNULL(AdjustedDaysPerMonth, maxDaysPerMonth)
													 else 0 end,0),2) GeneratedOverageAmount
					, paramSmGroupPercent SmGroupPercent
					, paramInterGroupPercent InterGroupPercent
					, paramLargeGroupPercent LargeGroupPercent
					, paramCMPercent CMPercent
					#unfortunately, to date, no idea where this comes from but used
					#only in ADM report and not in billing calculations
					#taken directly from AEP MS Access system
					, round(case when BilledAmount > maxDaysPerMonth
											then (maxDaysPerMonth -  (0.3497 * Small) - (0.2387 * Inter) - (0.1837 * Large)) / 1.0167
											else NULL
										end,2) AdjustedIndHours
				from sptmp_billingStudent) finalData
			on billingStudent.billingStudentId = finalData.billingStudentId
	set billingStudent.GeneratedBilledAmount  = finalData.GeneratedBilledAmount,
		billingStudent.GeneratedOverageAmount = finalData.GeneratedOverageAmount,
		billingStudent.SmGroupPercent = finalData.SmGroupPercent,
		billingStudent.InterGroupPercent = finalData.InterGroupPercent,
		billingStudent.LargeGroupPercent = finalData.LargeGroupPercent,
		billingStudent.CMPercent = finalData.CMPercent,
		billingStudent.AdjustedIndHours = finalData.AdjustedIndHours,
		billingStudent.DateLastUpdated = now(),
        billingStudent.LastUpdatedBy = paramCreatedBy
	where (billingStudent.GeneratedBilledAmount <> finalData.GeneratedBilledAmount or billingStudent.GeneratedBilledAmount is null)
		or (billingStudent.GeneratedOverageAmount <> finalData.GeneratedOverageAmount or billingStudent.GeneratedOverageAmount is null)
		or (billingStudent.SmGroupPercent <> finalData.SmGroupPercent or billingStudent.SmGroupPercent is null)
		or (billingStudent.InterGroupPercent <> finalData.InterGroupPercent or billingStudent.InterGroupPercent is null)
		or (billingStudent.LargeGroupPercent <> finalData.LargeGroupPercent or billingStudent.LargeGroupPercent is null)
		or (billingStudent.CMPercent <> finalData.CMPercent or  billingStudent.CMPercent is null)
		or (billingStudent.AdjustedIndHours <> finalData.AdjustedIndHours or billingStudent.AdjustedIndHours is null);
END
//