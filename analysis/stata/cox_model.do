/*----------------------------------------------------------------------------
	   Do file name: 			cox_model.do
	   Project: 				12
	   Date:					08/09/2022
	   Author:					Venexia Walker and Rachel Denholm
	   Description:			Reformating of CSV file and running cox models
	   Datasets used:			csv outcome files
	   Datasets created:		*_cox_model_* , *_stata_median_fup_*
	   Other output:			logfiles
   -----------------------------------------------------------------------------*/

local name "`1'"
local day0 "`2'"
* local extf "`3'"

* Set file paths

global projectdir `c(pwd)'
di "$projectdir"

* Set Ado file path

adopath + "$projectdir/analysis/stata/extra_ados"

* unzip the input data 

shell gunzip "./output/ready-`name'.csv.gz"

* Import and describe data

import delim using "./output/ready-`name'.csv", clear

des

* Filter data

keep patient_id exposure outcome fup_start fup_stop cox_weight cov_cat* cov_num* cov_bin*
drop cov_num_age_sq
duplicates drop

* Rename variables
rename cov_num_age age
rename cov_cat_region region

* Generate pre vaccination cohort dummy variable
local prevax_cohort = regexm("`name'", "_pre")
display "`prevax_cohort'"

* Replace NA with missing value that Stata recognises

ds , has(type string)
foreach var of varlist `r(varlist)' {
	replace `var' = "" if `var' == "NA"
}

* Reformat variables


foreach var of varlist exposure outcome fup_start fup_stop {
	split `var', gen(tmp_date) parse(-)
	gen year = real(tmp_date1)
	gen month = real(tmp_date2)
	gen day = real(tmp_date3)
	gen `var'_tmp = mdy(month, day, year)
	format %td `var'_tmp
	drop `var' tmp_date* year month day
	rename `var'_tmp `var'
}

* Encode non-numeric variables

foreach var of varlist region cov_bin* cov_cat* {
	di "Encoding `var'"
	local var_short = substr("`var'", 1, length("`var'") - 1) 
	encode `var', generate(`var_short'1)
	drop `var'
	rename `var_short'1 `var'
}

 * Shorten covariates names 
/*capture confirm variable cov_bin_overall_gi_and_symptoms
if !_rc {
 	rename cov_bin_overall_gi_and_symptoms cov_bin_gi_sym
	}*/

* Summarize missingness

misstable summarize

* Update follow-up end

replace fup_stop = fup_stop + 1
format fup_stop %td

* Make age spline

centile age, centile(10 50 90)
mkspline age_spline = age, cubic knots(`r(c_1)' `r(c_2)' `r(c_3)')

* Make outcome status variable

egen outcome_status = rownonmiss(outcome)


* Apply stset including IPW here as unsampled datasets will be provided with cox_weights set to 1

if `prevax_cohort'==1 {
	if "`day0'"=="TRUE" {
		stset fup_stop [pweight=cox_weight], failure(outcome_status) id(patient_id) enter(fup_start) origin(time mdy(01,01,2020))
		stsplit time, after(exposure) at(0 1 28 197 365 714)
		replace time = 714 if time==-1
	}
	else {
		stset fup_stop [pweight=cox_weight], failure(outcome_status) id(patient_id) enter(fup_start) origin(time mdy(01,01,2020))
		stsplit time, after(exposure) at(0 28 197 365 714)
		replace time = 714 if time==-1
	}
} 
else {
	if "`day0'"=="TRUE" {
		stset fup_stop [pweight=cox_weight], failure(outcome_status) id(patient_id) enter(fup_start) origin(time mdy(01,06,2021))
		stsplit time, after(exposure) at(0 1 28 197)
		replace time = 197 if time==-1
	} 
	else {
		stset fup_stop [pweight=cox_weight], failure(outcome_status) id(patient_id) enter(fup_start) origin(time mdy(01,06,2021))
		stsplit time, after(exposure) at(0 28 197)
		replace time = 197 if time==-1
	}
}
* Calculate study follow up

gen fup = _t - _t0
egen fup_total = total(fup)  

* Make days variables

if "`day0'"=="TRUE" {
	gen days0_1 = 0
	replace days0_1 = 1 if time==0
	tab days0_1
	gen days1_28 = 0
	replace days1_28 = 1 if time==1
	tab days1_28
} 
else {
	gen days0_28 = 0
	replace days0_28 = 1 if time==0
	tab days0_28
}

gen days28_197 = 0
replace days28_197 = 1 if time==28
tab days28_197

if `prevax_cohort'==1 {
	gen days197_365 = 0 
	replace days197_365 = 1 if time==197
	tab days197_365
	gen days365_714 = 0 
	replace days365_714 = 1 if time==365
	tab days365_714
}

* Run models and save output [Note: cannot use efron method with weights]

tab time outcome_status 

di "Total follow-up in days: " fup_total
bysort time: summarize(fup), detail

* Check if `name` contains "sub_sex"
if regexm("`name'", "sub_sex") {
stcox days*  age_spline1 age_spline2, strata(region) vce(r)
}
else{
stcox days* i.cov_cat_sex age_spline1 age_spline2, strata(region) vce(r)
}
est store min, title(Age_Sex)

stcox days* age_spline1 age_spline2 i.cov_cat_* cov_num_* cov_bin_*, strata(region) vce(r)
est store max, title(Maximal)

estout * using "output/ready-`name'_cox_model.txt", cells("b se t ci_l ci_u p") stats(risk N_fail N_sub N N_clust) replace 

* Calculate median follow-up among individuals with the outcome

keep if outcome_status==1
keep patient_id days* fup
rename fup tte
gen term = ""

if `prevax_cohort'==1 {
	if "`day0'"=="TRUE" {
		replace term = "days_pre" if days0_1==0 & days1_28==0 & days28_197==0 & days197_365==0 & days365_714==0
		replace term = "days0_1" if days0_1==1 & days1_28==0 & days28_197==0 & days197_365==0 & days365_714==0
		replace term = "days1_28" if days0_1==0 & days1_28==1 & days28_197==0 & days197_365==0 & days365_714==0
		replace term = "days28_197" if days0_1==0 & days1_28==0 & days28_197==1 & days197_365==0 & days365_714==0
		replace term = "days197_365" if days0_1==0 & days1_28==0 & days28_197==0 & days197_365==1 & days365_714==0
		replace term = "days365_714" if days0_1==0 & days1_28==0 & days28_197==0 & days197_365==0 & days365_714==1
	}
	else {
		replace term = "days_pre" if days0_28==0 & days28_197==0 & days197_365==0 & days365_714==0
		replace term = "days0_28" if days0_28==1 & days28_197==0 & days197_365==0 & days365_714==0
		replace term = "days28_197" if days0_28==0 & days28_197==1 & days197_365==0 & days365_714==0
		replace term = "days197_365" if days0_28==0 & days28_197==0 & days197_365==1 & days365_714==0
		replace term = "days365_714" if days0_28==0 & days28_197==0 & days197_365==0 & days365_714==1
	}
} 
else {
	if "`day0'"=="TRUE" {
		replace term = "days_pre" if days0_1==0 & days1_28==0 & days28_197==0
		replace term = "days0_1" if days0_1==1 & days1_28==0 & days28_197==0
		replace term = "days1_28" if days0_1==0 & days1_28==1 & days28_197==0	
		replace term = "days28_197" if days0_1==0 & days1_28==0 & days28_197==1
	}
	else {
		replace term = "days_pre" if days0_28==0 & days28_197==0
		replace term = "days0_28" if days0_28==1 & days28_197==0
		replace term = "days28_197" if days0_28==0 & days28_197==1
		replace term = "days197_535" if days0_28==0 & days28_197==0
	}
}

replace tte = tte + 28 if term == "days28_197"
replace tte = tte + 197 if term == "days197_365"
replace tte = tte + 365 if term == "days365_714"
replace tte = tte + 197 if term == "days197_535"
bysort term: egen median_tte = median(tte)
egen events = count(patient_id), by(term)

keep term median_tte events
duplicates drop

export delimited using "output/ready-`name'_median_fup.csv", replace
