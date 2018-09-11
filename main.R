library(plumber)
library(optparse)

option_list <- list(
  make_option("--port", type="integer", action="store", dest="port", default=8080, help="What port to serve on. Default is 8080.")
)
parser <- OptionParser(usage="%prog [options]", option_list=option_list)
args <- parse_args2(parser)
#print(args)

serve <- function() {
    app <- plumb('plumber.R')
    app$run(host='0.0.0.0', port=args$options$port)}

serve()