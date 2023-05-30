Octopub is a sample application designed to be deployed to a variety of platforms such as AWS Lambda, Kubernetes, and 
static web hosting. It also builds a number of test worker images, test scripts, and security packages.

## Maven feed

A number of packages including SBOM packages and Lambda artifacts, are pushed to a public Maven repo hosted at 
https://octopus-sales-public-maven-repo.s3.ap-southeast-2.amazonaws.com/snapshot.

* `com.octopus:octopub-frontend` - The static frontend website
* `com.octopus:octopub-frontend-sbom` - The static frontend website SBOM
* `com.octopus:products-microservice-lambda` - The product microservice AWS Lambda
* `com.octopus:products-microservice-liquidbase` - The product microservice Liquidbase database migration scripts
* `com.octopus:products-microservice-sbom` - The product microservice SBOM
* `com.octopus:audit-microservice-lambda` - The audit microservice AWS Lambda
* `com.octopus:audit-microservice-liquidbase` - The audit microservice Liquidbase database migration scripts
* `com.octopus:audit-microservice-sbom` - The audit microservice SBOM

## Docker images

The following images are built:

* `octopussamples/octopub-products-microservice` - the backend products service
* `octopussamples/octopub-products-microservice-mysql` - the backend products service configured to use an external MySQL database
* `octopussamples/octopub-audit-microservice` - the backend audits service
* `octopussamples/octopub-audit-microservice-mysql` - the backend audits service configured to use an external MySQL database
* `octopussamples/octopub-frontend` - the frontend web UI
* `octopussamples/postman-worker-image` - a worker image that includes Postman
* `octopussamples/cypress-worker-image` - a worker image that includes Cypress

## Helm charts

A number of helm charts are saved to the public Helm repo at 
https://octopus-sales-public-helm-repo.s3.ap-southeast-2.amazonaws.com/charts:

* `octopub-products-mysql` - Deploys the products microservice with support for a MySQL database.

## Local testing

To test Octopub locally, use the supplied Docker Compose file:

```bash
cd compose
docker-compose up
```

You can then access the page at http://localhost:5001.
