FROM --platform=$TARGETPLATFORM node AS build

ARG TARGETOS
ARG TARGETARCH

RUN echo "Building for $TARGETOS/$TARGETARCH"

WORKDIR /usr/src/app
COPY package.json ./
# Suggested fix from https://github.com/nodejs/docker-node/issues/1335 for ARM64
RUN yarn config set network-timeout 300000 && yarn install
COPY . .
RUN yarn build
RUN npm install --global @cyclonedx/cyclonedx-npm
RUN cyclonedx-npm --ignore-npm-errors --output-file /bom.json

FROM build AS build-with-tools
USER root
RUN apt-get update; apt-get install -y jq curl

FROM build-with-tools AS frontend-amd64
RUN curl -s https://api.github.com/repos/mcasperson/UltimateDockerLauncher/releases/latest | jq -r '.assets[] | select(.name|match("udl$")) | .browser_download_url' | xargs -I {} curl -L -o /opt/udl {} 

FROM build-with-tools AS frontend-arm64
RUN curl -s https://api.github.com/repos/mcasperson/UltimateDockerLauncher/releases/latest | jq '.assets[] | select(.name|match("udl_linux_arm64$")) | .browser_download_url' | xargs -I {} curl -L -o /opt/udl {} 

FROM frontend-${TARGETARCH} AS final
RUN chmod +x /opt/udl

FROM nginxinc/nginx-unprivileged:latest
USER root

COPY --from=final /usr/src/app/build /usr/share/nginx/html/
RUN chown -R nginx:nginx /usr/share/nginx/html
COPY --from=build /bom.json /bom.json
USER 101
ENTRYPOINT []
CMD [  "/opt/udl", "nginx", "-g", "daemon off;" ]
