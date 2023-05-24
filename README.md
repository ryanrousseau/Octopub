Octopub is a sample application designed to be deployed to a variety of platforms such as AWS Lambda, Kubernetes, and 
static web hosting. It also builds a number of test worker images, test scripts, and security packages.

## Maven feed

A number of packages including SBOM packages and Lambda artifacts, are pushed to an public Maven repo hosted at 
https://octopus-sales-public-maven-repo.s3.ap-southeast-2.amazonaws.com/snapshot.

## Docker images

The following images are built:

* `octopussamples/octopub-products` - the backend products service
* `octopussamples/octopub-frontend` - the frontend web UI
* `octopussamples/postman-worker-image` - a worker image that includes Postman
* `octopussamples/cypress-worker-image` - a worker image that includes Cypress