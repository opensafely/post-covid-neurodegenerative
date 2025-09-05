* ==============================================================================
*  Setup and input
* ==============================================================================

* Specify parameters

local name "`1'"
local cutpoints "`2'"
local study_start "`3'"

/*
* Specify parameters locally

local name "cohort_prevax-main-dem_any"
local cutpoints "1;28;183;365;730;1065;1582"
local study_start "2020-01-01"
*/

* Set Ado file path

adopath + "analysis/extra_ados"

* Read and describe data

use "./output/model/ready-`name'.dta", clear
describe

* ==============================================================================
*  Convert args for use by Stata
* ==============================================================================

local cutpoints = subinstr("0;`cutpoints'", ";", " ", .)
di "`cutpoints'"

local cutpoints_last = word("`cutpoints'", wordcount("`cutpoints'"))
di "`cutpoints_last'"

* ==============================================================================
*  Data preparation (matches R preprocessing)
* ==============================================================================

* Filter data

keep patient_id exposure outcome fup_start fup_stop cox_weight cov_cat* strat* cov_num* cov_bin* 
drop cov_num_age_sq
duplicates drop

* Rename variables

rename cov_num_age age
rename strat_cat_region region

* Generate sex indicator

local sub_sex = regexm("`name'", "sub_sex")
display "`sub_sex'"

* Replace NA with missing value that Stata recognises

ds , has(type string)
foreach var of varlist `r(varlist)' {
	replace `var' = "" if `var' == "NA"
}

* Reformat date variables (already numeric)
foreach var of varlist exposure outcome fup_start fup_stop {
    format `var' %td
}

* Encode only string variables
foreach var of varlist region cov_bin* cov_cat* {
    di "Checking `var'..."
    capture confirm string variable `var'
    if !_rc {  // _rc = 0 means it's a string
        di "Encoding `var'"
        local var_short = substr("`var'", 1, length("`var'") - 1)
        encode `var', generate(`var_short'1)
        drop `var'
        rename `var_short'1 `var'
    }
    else {
        di "`var' is already numeric, skipping encode"
    }
}

* ==============================================================================
*  Summary checks
* ==============================================================================

misstable summarize

* ==============================================================================
*  Time-to-event setup (stset)
* ==============================================================================

* Update follow-up end

replace fup_stop = fup_stop + 1
format fup_stop %td

* Make age spline

centile age, centile(10 50 90)
mkspline age_spline = age, cubic knots(`r(c_1)' `r(c_2)' `r(c_3)')

* Make outcome status variable

egen outcome_status = rownonmiss(outcome)

* ==============================================================================
*  Total number of patients and exposed patients
* ==============================================================================

egen N_total = count(patient_id)
egen N_exposed = total(!missing(exposure))

* Apply stset including IPW here as unsampled datasets will be provided with cox_weights set to 1

gen origin_date = daily("`study_start'", "YMD")
stset fup_stop [pweight=cox_weight], failure(outcome_status) id(patient_id) enter(fup_start) origin(origin_date)
stsplit time, after(exposure) at(`cutpoints')
replace time = `cutpoints_last' if time==-1
	
* ==============================================================================
*  Person-time and events (matches R collapse step)
* ==============================================================================

gen fup = _t - _t0
egen fup_total = total(fup)  

* Person-time and events aggregated by time interval

egen person_time_total = total(fup), by(time)
egen N_events = total(outcome_status), by(time)

* ==============================================================================
* Median follow-up among those with the event
* ==============================================================================

gen tte = fup if outcome_status==1
egen outcome_time_median_in_term = median(tte), by(time)

* ==============================================================================
*  Define indicator variables for each time period
* ==============================================================================

* Count the number of breakpoints
local n : word count `cutpoints'

* Loop over the breakpoints to generate interval variables
forvalues i = 1/`=`n'-1' {
    local start = word("`cutpoints'", `i')
    local end   = word("`cutpoints'", `=`i'+1')
    
    * Generate variable name dynamically
    local varname = "days`start'_`end'"
    
    * Generate the variable: 1 if time == start (or adjust to range if desired)
    gen `varname' = (time == `start')
    tab `varname'
}

* ==============================================================================
*  Create term variable that indicates which days* the row refers to
* ==============================================================================

* Identify day variables
ds days*, has(type numeric)
local dayvars `r(varlist)'
	
* Generate empty variable
gen str20 term = ""

* Loop over each variable
foreach var of local dayvars {
    replace term = "`var'" if `var' == 1
}

* If all are 0, you can set "days_pre"
replace term = "days_pre" if term == ""

* ==============================================================================
*  Based on term, add outcome time that has already passed
* ==============================================================================
preserve

gen start_term = .
gen match = regexs(1) if regexm(term, "days([0-9]+)_")
replace start_term = real(match)
drop match

gen outcome_time_median = outcome_time_median_in_term
replace outcome_time_median = outcome_time_median_in_term + start_term if term!="days_pre"

order term N_total N_exposed N_events person_time_total outcome_time_median   
keep term N_total N_exposed N_events person_time_total outcome_time_median 
duplicates drop

* ==============================================================================
*  Save descriptive output (aligns with R's descriptive summary)
* ==============================================================================

save "./output/model/stata_tmp-`name'.dta", replace

* ==============================================================================
* Run models and save output [Note: cannot use efron method with weights]
* ==============================================================================
restore

tab time outcome_status 

di "Total follow-up in days: " fup_total
bysort time: summarize(fup), detail

if `sub_sex'==1 {
	stcox days* age_spline1 age_spline2, strata(region) vce(r)
	est store min, title(Age_Sex)
	stcox days* age_spline1 age_spline2 i.cov_cat_* cov_num_* cov_bin_*, strata(region) vce(r)
	est store max, title(Maximal)
}
else {
	stcox days* i.cov_cat_sex age_spline1 age_spline2, strata(region) vce(r)
	est store min, title(Age_Sex)
	stcox days* age_spline1 age_spline2 i.cov_cat_* cov_num_* cov_bin_*, strata(region) vce(r)
	est store max, title(Maximal)	
}

* Save coefficients with CIs
estout * using "./output/model/stata_tmp_output-`name'.txt", cells("b se t ci_l ci_u p") stats(risk N_fail N_sub N N_clust) replace 

* ==============================================================================
* Format stata model output
* ==============================================================================

* Step 1. Import text file as raw

import delimited using "./output/model/stata_tmp_output-`name'.txt", clear stringcols(_all)

* Step 2. Rename columns properly

rename v1 term
rename v2 b_min
rename v3 se_min
rename v4 t_min
rename v5 lci_min
rename v6 uci_min
rename v7 p_min
rename v8 b_max
rename v9 se_max
rename v10 t_max
rename v11 lci_max
rename v12 uci_max
rename v13 p_max
drop in 1/2
* Drop last 5 rows (risk, N_fail, etc.)
count
drop in `=`r(N)'-4'/`r(N)'
drop p_* t_*

* Step 3. Convert to numeric where possible
destring b_min se_min lci_min uci_min ///
         b_max se_max lci_max uci_max, replace force

* Step 4. Calculate HRs from log-HR (b_min, b_max)
gen hr_min = exp(b_min)
gen conf_low_min = exp(lci_min)
gen conf_high_min = exp(uci_min)

gen hr_max = exp(b_max)
gen conf_low_max = exp(lci_max)
gen conf_high_max = exp(uci_max)

* Step 5. Reshape to long form for model variable

reshape long b_ se_ lci_ uci_ hr_ conf_low_ conf_high_, i(term) j(model) string

* Label models
replace model = "mdl_age_sex" if model=="min"
replace model = "mdl_max_adj" if model=="max"

* Rename for clarity
rename b_ lnhr
rename se_ se_lnhr
rename hr_ hr
rename conf_low_ conf_low
rename conf_high_ conf_high

*Relabel for readability
replace term = "cov_cat_sex=Female" if term=="1.cov_cat_sex"
replace term = "cov_cat_sex=Male" if term=="2.cov_cat_sex"
replace term = "cov_cat_imd=1 (most deprived)" if term=="1.cov_cat_imd"
replace term = "cov_cat_imd=2" if term=="2.cov_cat_imd"
replace term = "cov_cat_imd=3" if term=="3.cov_cat_imd"
replace term = "cov_cat_imd=4" if term=="4.cov_cat_imd"
replace term = "cov_cat_imd=5 (least deprived)" if term=="5.cov_cat_imd"

*tidy dataset by removing unnessary rows
drop if model=="mdl_age_sex" & !(strpos(term,"age_spline") | strpos(term,"cov_cat_sex=Male") | strpos(term,"days"))
drop if strpos(term,"cov_cat_sex=Female") | strpos(term,"cov_cat_imd=1 (most deprived)")

*Step 6. Merge with survival information 

merge m:1 term using "./output/model/stata_tmp-`name'.dta", nogen
sort model term

*Step 7. Add metadata fields

gen strata_warning = ""
gen surv_formula = ""
replace surv_formula = "Surv(_t0, _t, _d) ~ days* + age_spline1 + age_spline2 + i.cov_cat_sex strata(region)" if model=="mdl_age_sex"
replace surv_formula = "Surv(_t0, _t, _d) ~ days* + age_spline1 + age_spline2 + i.cov_cat_* + cov_num_* + cov_bin_* strata(region)" if model=="mdl_max_adj"

*Step 8. Save final CSV

export delimited using "./output/model/stata_model_output-`name'.csv", replace
