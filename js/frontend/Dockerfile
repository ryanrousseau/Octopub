FROM node as build
ARG ARCH=amd64
WORKDIR /usr/src/app
COPY package.json ./
# Suggested fix from https://github.com/nodejs/docker-node/issues/1335 for ARM64
RUN yarn config set network-timeout 300000
RUN yarn install
COPY . .
RUN yarn build
RUN npm install --global @cyclonedx/cyclonedx-npm
RUN cyclonedx-npm --ignore-npm-errors --output-file /bom.json

FROM nginxinc/nginx-unprivileged:latest
USER root
RUN apt-get update; apt-get install -y jq curl
# Download the latest version of udl
RUN if [ "$ARCH" = "amd64" ]; then \
curl -s https://api.github.com/repos/mcasperson/UltimateDockerLauncher/releases/latest | \
    jq '.assets[] | select(.name|match("udl$")) | .browser_download_url' | \
    xargs -I {} curl -L -o /opt/udl {} \
    elif [ "$ARCH" = "arm64" ]; then \
    curl -s https://api.github.com/repos/mcasperson/UltimateDockerLauncher/releases/latest | \
    jq '.assets[] | select(.name|match("udl_linux_arm64$")) | .browser_download_url' | \
    xargs -I {} curl -L -o /opt/udl {} \
fi
RUN chmod +x /opt/udl
COPY --from=build /usr/src/app/build /usr/share/nginx/html/
RUN chown -R nginx:nginx /usr/share/nginx/html
COPY --from=build /bom.json /bom.json
USER 101
ENTRYPOINT []
CMD [  "/opt/udl", "nginx", "-g", "daemon off;" ]
