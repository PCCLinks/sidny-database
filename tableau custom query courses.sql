select tmpResultsEnroll.*
, (cast(left(cast(minEnrollTerm as char(10)),4) as unsigned)*4)+(cast(right(cast(minEnrollTerm as char(10)),1) as unsigned)) as minEnrollTerm_Nominal
, (cast(left(cast(maxExitTerm as char(10)),4) as unsigned)*4)+(cast(right(cast(maxExitTerm as char(10)),1) as unsigned)) as maxExitTerm_Nominal
, yesGedPassed = 'Y' OR ytcGedPassed = 'Y' as passedGED
, case when length(yesGedTerm) > 0 then yesGedTerm
	else ytcGedTerm
	end as gedPassTerm_Combined
, case when length(yesGedTerm) > 0 
	then (cast(left(cast(yesGedTerm as char(10)),4) as unsigned)*4)+(cast(right(cast(yesGedTerm as char(10)),1) as unsigned)) 
	else (cast(left(cast(ytcGedTerm as char(10)),4) as unsigned)*4)+(cast(right(cast(ytcGedTerm as char(10)),1) as unsigned)) 
	end as gedPassTerm_Nominal
, case when earnedAward > 0 then 1 else 0 end as earnedAward
, ESLCheck
, swvlinks_course.*
, (cast(left(cast(Term as char(10)),4) as unsigned)*4)+(cast(right(cast(Term as char(10)),1) as unsigned)) as term_Nominal

from tmpResultsEnroll

    left join (
		select Stu_ID
        , max(case when length(MAJOR_DESC) > 1 then 1 else 0 end) as earnedAward
        from banner.swvlinks_award
        group by STU_ID
        ) awards
			on awards.Stu_id = tmpResultsEnroll.bannerGNumber

	left join (
		select STU_ID
		, max(case when Subj = "ESL" OR Subj = "ESOL" then 1 else 0 end) as ESLCheck
        from banner.swvlinks_course
        group by STU_ID
			) ESL
				on ESL.Stu_ID = tmpResultsEnroll.bannerGNumber
                
	left join (
		select DISTINCT STU_ID
        , TERM
        , CRN
        , SUBJ
        , CRSE
        , LEVL
        , TITLE
        , CREDITS
        , GRADE
        , PASSED 
        from banner.swvlinks_course	
    
		) swvlinks_course	
			on swvlinks_course.Stu_ID = tmpResultsEnroll.bannerGNumber