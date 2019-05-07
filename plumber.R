# R Plumber API to predict marathon time

# load required packages
library(jsonlite)

# load model object and factor levels
load("/opt/ml/marathon_model.RData")

# function to convert HMS to seconds
toSeconds <- function(x){
  if (!is.character(x)) stop("x must be a character string of the form H:M:S")
  if (length(x)<=0)return(x)
  
  unlist(
    lapply(x,
           function(i){
             i <- as.numeric(strsplit(i,':',fixed=TRUE)[[1]])
             if (length(i) == 3) 
               i[1]*3600 + i[2]*60 + i[3]
             else if (length(i) == 2) 
               i[1]*60 + i[2]
             else if (length(i) == 1) 
               i[1]
           }  
    )  
  )  
} 

# function to convert seconds to HMS
toHMS <- function(vec){
  # check that numeric vector
  if (!is.numeric(vec)) stop("vector must be a numeric")
  if (length(vec)<=0) return(vec)
  
  fxn <- function(x) {
    H <- formatC(x %/% 3600, width=2, flag="0")
    M <- formatC(x %% 3600 %/% 60, width=2, flag="0")
    seconds <- x %% 60
    # formatting for seconds
    if(seconds < 10) { 
      S <- formatC(x %% 60, width=2, flag="0", digits=1) } else 
        S <- formatC(x %% 60, width=2, flag="0", digits=2)
    
    paste(H, M, S, sep = ":")
  }
  
  # apply to all in vector
  lapply(vec, fxn)
} 



#' Ping to show server is there
#' @get /ping
function() {
  return('')}


#' Handles scoring requests. SageMaker requires it to be a post to /invocations
#' @param req 
#' @post /invocations
mpred <- function(req, res) {
  
  # read input data 
  preddat <- as.data.frame(fromJSON(req$postBody), stringsAsFactors = FALSE)
  #preddat <- as.data.frame(fromJSON("example.json"), stringsAsFactors = FALSE)

  preddat$hmaratime <- toSeconds(preddat$hmtime)
  preddat$gender <- factor(preddat$gender, levels = factor_levels$gender)
  
  m_pred <- predict(lm2_save, newdata = preddat, se.fit = TRUE)
  
  m_out <- as.character(toHMS(m_pred$fit))
  
  return(list(marathon_time = m_out))
  
}



