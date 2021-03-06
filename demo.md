---
title: "SageMaker R Model Deployment"
author: "John Stanton-Geddes"
date: "9/12/2018"
output: 
  html_document:
    keep_md: true
---



## Model Training

In this case, I use a model that I trained in [another project](https://github.com/johnstantongeddes/RacePerformancePredictor) to predict a runner's marathon time from their half-marathon time. 


```r
load("marathon_model.RData")

anova(lm2_save)
```

```
## Analysis of Variance Table
## 
## Response: maratime
##                             Df     Sum Sq    Mean Sq F value    Pr(>F)    
## poly(hmaratime, 2)           2 6176318657 3088159329     Inf < 2.2e-16 ***
## gender                       1       1618       1618     Inf < 2.2e-16 ***
## poly(hmaratime, 2):gender    2   49805763   24902881     Inf < 2.2e-16 ***
## Residuals                 1300          0          0                      
## ---
## Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1
```

## Model Deployment

For a standardized deployment process, SageMaker needs a custom algorithm packaged in a Dockerfile such as this:


```r
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
```

The `deploy_to_sagemaker.sh` script runs through the deployment process. 

- Set parameters including the algorithm name and use `aws cli` tools to get information about the AWS account that are needed for model deployment
- Create a repository for the Docker container in ECR
- Build and push to the ECR repo
- Create a SageMaker model pointing to the ECR repo
- Configure a SageMaker endpoint pointing to the SageMaker model
- Create a SageMaker endpoing pointing to the SageMaker configuration

Note that once you've created the SageMaker endpoint, you have an EC2 instance that's always up and running, and you'll be getting charged! Even the smallest instance will cost you $50/mth.


## Prediction

Once you have the model deployed, you can use the SageMaker CLI to pass a JSON file for predicition. The beauty of this is that users of your model don't need to know anything about your model! They just pass in JSON and get a response back!


```r
system("aws runtime.sagemaker invoke-endpoint --endpoint-name jsg-sgmkr-demo-endpoint --body '{\"hmtime\": \"1:40:00\", \"gender\": \"M\"}' response.txt")

result <- jsonlite::fromJSON("response.txt")
result <- unlist(result$marathon_time)
```

For a runner with a half-marathon time of 1:40, this model predicts they'd run a marathon in 3:45:48. 
