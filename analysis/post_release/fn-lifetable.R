# Function for making life tables that requires two inputs:
# (1) model_output
# (2) aer_input [adapted Table 2 with age and sex groupings]

lifetable <- function(model_output, aer_input) {
  
  # Filter model output --------------------------------------------------------
  print('Filter model output')
  
  model_output <- model_output[model_output$analysis==aer_input$analysis &
                                 model_output$outcome==aer_input$outcome &
                                 model_output$cohort==aer_input$cohort,]
  
  # Step 0. Create life table --------------------------------------------------
  print('Step 0. Create life table')
  
  lifetable <- data.frame(analysis = aer_input$analysis, 
                          outcome = aer_input$outcome, 
                          cohort = aer_input$cohort,
                          aer_age = aer_input$aer_age,
                          aer_sex = aer_input$aer_sex,
                          days = c(0:(max(model_output$time_period_end)-1)),
                          stringsAsFactors = FALSE)
  
  # Step 1. Average daily incidence of the outcome in the unexposed ------------
  print('Step 1. Average daily incidence of the outcome in the unexposed')
  
  lifetable$incidence_unexp <- aer_input$unexposed_events / aer_input$unexposed_person_days
  
  # Step 2. Cumulative risk over time in the unexposed -------------------------
  print('Step 2. Cumulative risk over time in the unexposed')
  
  lifetable$cumulative_survival_unexp <- cumprod(1 - lifetable$incidence_unexp) 
  
  # Step 3. Add hazard ratios --------------------------------------------------
  print('Step 3. Add hazard ratios')
  
  lifetable$hr <- NA
  
  for(i in 1:nrow(model_output)){
    tmp <- model_output[i,]
    lifetable$hr <- ifelse(lifetable$days >= tmp$time_period_start & lifetable$days < tmp$time_period_end, tmp$hr, lifetable$hr)
  }
  
  # Step 4. Predict the expected cumulative survival in the exposed ------------
  print('Step 4. Predict the expected cumulative survival in the exposed')
  
  lifetable$cumulative_survival_exp <- cumprod(1 - (lifetable$hr * lifetable$incidence_unexp))
  
  # Step 5. Calculate the daily excess risk ------------------------------------
  print('Step 5. Calculate the daily excess risk')
  
  lifetable$cumulative_difference_absolute_excess_risk <- lifetable$cumulative_survival_unexp - lifetable$cumulative_survival_exp
  
  # Return output for compiling ------------------------------------------------
  print('Return output for compiling')
  
  return(lifetable)
  
}