FROM ubuntu:16.04
MAINTAINER John Stanton-Geddes <John.Stanton-Geddes@coxautoinc.com>
RUN apt-get -y update && apt-get install -y --no-install-recommends \
    wget \
    r-base \
    r-base-dev \
    ca-certificates
    
RUN R -e "install.packages(c('plumber', 'optparse', 'jsonlite'), repos='https://cloud.r-project.org')"

COPY marathon_model.RData /opt/ml/marathon_model.RData
COPY main.R /opt/ml/main.R
COPY plumber.R /opt/ml/plumber.R

WORKDIR /opt/ml

ENTRYPOINT ["/usr/bin/Rscript", "main.R", "--no-save"]
