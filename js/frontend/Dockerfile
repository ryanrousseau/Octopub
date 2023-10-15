FROM node as build
WORKDIR /usr/src/app
COPY package.json ./
RUN yarn install
COPY . .
RUN yarn build
RUN npm install --global @cyclonedx/cyclonedx-npm
RUN cyclonedx-npm --ignore-npm-errors --output-file /bom.json

FROM nginxinc/nginx-unprivileged:latest
USER root
RUN apt-get update; apt-get install -y jq curl
# Download the latest version of udl
RUN curl -s https://api.github.com/repos/mcasperson/UltimateDockerLauncher/releases/latest | \
    jq '.assets[] | select(.name|match("udl$")) | .browser_download_url' | \
    xargs -I {} curl -L -o /opt/udl {}
RUN chmod +x /opt/udl
COPY --from=build /usr/src/app/build /usr/share/nginx/html/
RUN chown -R nginx:nginx /usr/share/nginx/html
COPY --from=build /bom.json /bom.json
USER 101
ENTRYPOINT []
CMD [  "/opt/udl", "nginx", "-g", "daemon off;" ]
