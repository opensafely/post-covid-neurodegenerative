# Rounding function for redaction ----------------------------------------------

roundmid_any <- function(x, to=1){
  # like ceiling_any, but centers on (integer) midpoint of the rounding points
  ceiling(x/to)*to - (floor(to/2)*(x!=0))
}

# Function to make display numbers ---------------------------------------------

display <- function(x, to=1){
  ifelse(x>=100,sprintf("%.0f",x),ifelse(x>=10,sprintf("%.1f",x),sprintf("%.2f",x)))
}