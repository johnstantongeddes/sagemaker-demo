library(jsonlite)

#' Ping to show server is there
#' @get /ping
function() {
  return('')}

#' Handles scoring requests. SageMaker requires it to be a post to /invocations
#' @param req 
#' @post /invocations
#' @serializer unboxedJSON
function(req) {
  data <- fromJSON(req$postBody)    
  cat(format(data))
  if (data$debt < 10000) {
    return(list(result="Approved"))
  }
  else {
    return(list(result="Denied"))
  }
}