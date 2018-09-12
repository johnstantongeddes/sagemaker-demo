SageMaker R Model Deployment Demo
=====================================

*John Stanton-Geddes*

*12 September, 2018*

## Description

AWS launched their [SageMaker](https://aws.amazon.com/sagemaker/) platform to build and deploy machine learning models at reInvent 2017. 

The platform has three main features

- Hosted Jupyter notebooks
- Training of built-in models 
- Model deployment

While the first two features are likely of interest to software engineers, the 'model deployment' option is appealing to data scientists with existing model development workflows with Python or R as you can use SageMaker to host your model. The advantages of this are that SageMaker will take care of:

> auto-scaling Amazon ML instances across multiple availability zones for high redundancy. Just specify the type of instance, and the maximum and minimum number desired, and Amazon SageMaker takes care of the rest. It will launch the instances, deploy your model, and set up the secure HTTPS endpoint for your application. Your application simply needs to include an API call to this endpoint to achieve low latency / high throughput inference.

However, for R users, there are few exisiting resources for how to use SageMaker for deployment, and even the official [amazon-sagemaker-examples GitHub R repo](https://github.com/awslabs/amazon-sagemaker-examples/tree/master/advanced_functionality/r_bring_your_own) uses a Jupyter notebook and `boto3` for many of the steps. Another example on the [AWS blog](https://aws.amazon.com/blogs/machine-learning/using-r-with-amazon-sagemaker/) uses `reticulate` to access the Python SDK to train and deploy a model using R.  

In this repo, I create a *mininum working example* of how to deploy a model *previously* developed in R to SageMaker. This functionality is important as it allows us to use any model formulation we want, and not just the pre-built ones available in SageMaker. For fun, the model I use is one I created in a [side-project](https://github.com/johnstantongeddes/RacePerformancePredictor) to predict a runner's marathon time from their half-marathon time. 

A key point is that *any model* developed in R that is saved as an `.Rdata` file (with factor levels and any other applicable model info) could be used in this model deployment process. 

This repository is a *minimum working example* and important topics such as configuration of SageMaker, unit testing and error handling of the prediction function, supervising the R process to ensure availability, and running multiple process to optimize instance usage are not covered here.

An important warning is for handling of factor levels that were not observed in model training that may be present at prediction. Proper error handling of this is crucial, though not covered here. However, in generating the model object to be deployed, this code chunk will save the necessary components of a linear model and observed factor levels to use in the prediction function.

```
model <- lm(y ~ x1 + x2 , data = training_data)


# Save factor levels for scoring
factor_levels <- lapply(training_data[, sapply(training_data, is.factor), drop=FALSE],
                        function(x) {levels(x)})

# Generate outputs
model <- model[!(names(model) %in% c('x', 'residuals', 'fitted.values'))]
attributes(model)$class <- 'lm'
save(model, factor_levels, file = 'model_for_deployment.RData')
```

Within the prediction function, the variable should be reassigned as a factor using the saved factor levels.

```
preddat$x1 <- factor(preddat$x1, levels = factor_levels$x1)
```


## Required Knowledge

Topics not covered here that are necessary for this to work:

- How to setup and run RStudio Server on an AWS EC2 instance. [RStudio supported version](https://aws.amazon.com/marketplace/pp/B06W2G9PRY).
- [Docker Basics](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/docker-basics.html)
- AWS [Elastic Container Registry](https://aws.amazon.com/ecr/)
- AWS [Identity and Access Management](https://aws.amazon.com/iam/)


