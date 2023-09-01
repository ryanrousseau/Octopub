# Run from the root directory with
# docker build -f docker/selfcontained/Dockerfile .
FROM eclipse-temurin:11 AS builder

# add pom.xml and source code
ADD java /java
RUN cd /java; ./mvnw install
RUN cd /java/products-microservice; ./mvnw package

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt-get install -y nodejs
RUN npm install --global yarn

ADD js/frontend /js
RUN cd /js; yarn install; yarn build

FROM nginxinc/nginx-unprivileged
RUN DEBIAN_FRONTEND=noninteractive \
      apt-get update \
      && apt-get install -y supervisor default-jdk \
      && rm -rf /var/lib/apt/lists/*
COPY --from=builder /js/build /usr/share/nginx/html/
COPY --from=builder /java/products-microservice/target/products-microservice-runner.jar /opt

COPY docker/selfcontained/nginx.conf /etc/nginx/nginx.conf
COPY docker/selfcontained/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD ["/usr/bin/supervisord"]