Octopub is a sample application designed to be deployed to a variety of platforms such as AWS Lambda, Kubernetes, and
static web hosting. It also builds a number of test worker images, test scripts, and security packages.

## Maven feed

A number of packages including SBOM packages and Lambda artifacts, are pushed to a public Maven repo hosted at
https://octopus-sales-public-maven-repo.s3.ap-southeast-2.amazonaws.com/snapshot.

* `com.octopus:octopub-frontend` - The static frontend website
* `com.octopus:octopub-frontend-sbom` - The static frontend website SBOM
* `com.octopus:products-microservice-lambda` - The product microservice AWS Lambda
* `com.octopus:products-microservice-gcf-jar` - The product microservice Google Cloud Function artifact
* `com.octopus:products-microservice-windows` - The product microservice as a Windows executable
* `com.octopus:products-microservice-jar` - The product microservice uber jar
* `com.octopus:products-microservice-systemd` - The product microservice systemd service file
* `com.octopus:products-microservice-mysql-jar` - The product microservice uber jar with MySQL
* `com.octopus:products-microservice-liquidbase` - The product microservice Liquidbase database migration scripts. The changelog file is called `changeLog.xml`.
* `com.octopus:products-microservice-sbom` - The product microservice SBOM
* `com.octopus:audit-microservice-lambda` - The audit microservice AWS Lambda
* `com.octopus:audit-microservice-jar` - The audit microservice uber jar
* `com.octopus:audit-microservice-systemd` - The audit microservice systemd service file
* `com.octopus:audit-microservice-mysql-jar` - The audit microservice uber jar with MySQL
* `com.octopus:audit-microservice-liquidbase` - The audit microservice Liquidbase database migration scripts. The changelog file is called `changeLog.xml`.
* `com.octopus:audit-microservice-sbom` - The audit microservice SBOM

## Downloading files locally

You can download Zip Maven artifacts locally with a command like:

```
mvn org.apache.maven.plugins:maven-dependency-plugin:3.6.0:get "-DremoteRepositories=https://octopus-sales-public-maven-repo.s3.ap-southeast-2.amazonaws.com/snapshot/" -Dartifact=com.octopus:products-microservice-lambda:LATEST:zip
```

Jar files are downloaded with a command like:

```
mvn org.apache.maven.plugins:maven-dependency-plugin:3.6.0:get "-DremoteRepositories=https://octopus-sales-public-maven-repo.s3.ap-southeast-2.amazonaws.com/snapshot/" -Dartifact=com.octopus:products-microservice-gcf-jar:LATEST:jar
```


Replace `com.octopus:products-microservice-lambda` with the artifact ID listed in the previous section.

## Docker images

The following images are built:

| Image                                              | Description                                                               | Port  | User ID | Group ID | Filesystem Write Access Required |
|----------------------------------------------------|---------------------------------------------------------------------------|-------|---------|----------|----------------------------------|
| octopussamples/octopub-products-microservice       | The backend products service with embedded database                       | 8083  | 1001    | 1001     | true                             |
| octopussamples/octopub-products-microservice-mysql | The backend products service configured to use an external MySQL database | 8083  | 1001    | 1001     | true                             |
| octopussamples/octopub-audit-microservice          | The backend audits service with embedded database                         | 10000 | 1001    | 1001     | true                             |
| octopussamples/octopub-audit-microservice-mysql    | The backend audits service configured to use an external MySQL database   | 10000 | 1001    | 1001     | true                             |
| octopussamples/octopub-frontend                    | The frontend web UI                                                       | 8080  | 101     | 101      | true                             |
| octopussamples/octopub-selfcontained               | A self contained image with the frontend and backend services             | 8080  | 101     | 101      | true                             |
| octopussamples/postman-worker-image                | A worker image that includes Postman                                      |       |         |          |                                  |
| octopussamples/cypress-worker-image                | A worker image that includes Cypress                                      |       |         |          |                                  |

## Helm charts

A number of helm charts are saved to the public Helm repo at
https://octopus-sales-public-helm-repo.s3.ap-southeast-2.amazonaws.com/charts:

* `octopub-products-mysql` - Deploys the products microservice with support for a MySQL database.
* `octopub-audits-mysql` - Deploys the audits microservice with support for a MySQL database.
* `octopub-frontend` - Deploys the frontend.

Install these charts locally with the following commands:

```bash
helm repo add SolutionEngineering https://octopus-sales-public-helm-repo.s3.ap-southeast-2.amazonaws.com/charts
helm upgrade -i octopubdb oci://registry-1.docker.io/bitnamicharts/mysql
helm upgrade -i --set database.hostname=octopubdb-mysql --set database.password=$(kubectl get secret --namespace default octopubdb-mysql -o jsonpath="{.data.mysql-root-password}" | base64 -d) octopusprod SolutionEngineering/octopub-products-mysql
helm upgrade -i \
  --set productEndpointOverride=http://$(kubectl get services octopusprod-octopub-products-mysql -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")/api/products \
  octopusweb SolutionEngineering/octopub-frontend
```

## Local testing

To test Octopub locally, use the supplied Docker Compose file:

```bash
cd compose
docker-compose up
```

You can then access the page at http://localhost:5001.

## Database migration examples

If you wish to demonstrate a database migration using the `com.octopus:products-microservice-liquidbase` or 
`com.octopus:audit-microservice-liquidbase` packages, the script below provdes an example with the Liquibase
docker image:

```bash
echo "##octopus[stdout-verbose]"
docker pull liquibase/liquibase
echo "##octopus[stdout-default]"

cd products-microservice-liquidbase

docker run -e INSTALL_MYSQL=true --rm -v ${PWD}:/liquibase/changelog liquibase/liquibase \
  "--changeLogFile=changeLog.xml" \
  "--username=#{Database.Username}" \
  "--password=#{Database.Password}" \
  "--url=jdbc:mysql://#{Database.Hostname}:3306/product?createDatabaseIfNotExist=true" \
  update
```

## Configuration Options

### Frontend App

The configuration of the frontend web app is done by modifying the `config.json` file. This can be done two ways:

1. Modify the JSON directly when the static web app is uploaded directly to a hosting platform
2. Configure the Docker image to modify the JSON when the container is started

Option 2 is achieved using the [Ultimate Docker Launcher](https://github.com/mcasperson/UltimateDockerLauncher) (UDL), which
is baked into the Docker images. UDL modifies data files, like config files, based on environment variables. A common
set of environment variables is:

* `UDL_SKIPEMPTY_SETVALUE_1` = `[/usr/share/nginx/html/config.json][productEndpoint]/#{ProductsMicroserviceBaseUrl}/api/products`
* `UDL_SKIPEMPTY_SETVALUE_2` = `[/usr/share/nginx/html/config.json][productHealthEndpoint]/#{ProductsMicroserviceBaseUrl}/health/products`
* `UDL_SKIPEMPTY_SETVALUE_3` = `[/usr/share/nginx/html/config.json][auditEndpoint]/#{ProductsMicroserviceBaseUrl}/api/audits`
* `UDL_SKIPEMPTY_SETVALUE_4` = `[/usr/share/nginx/html/config.json][auditHealthEndpoint]/#{ProductsMicroserviceBaseUrl}/health/audits`