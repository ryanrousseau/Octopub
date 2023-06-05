FROM node as build
WORKDIR /usr/src/app
COPY package.json ./
RUN yarn install
COPY . .
RUN yarn build

FROM nginxinc/nginx-unprivileged:latest
USER root
RUN apt-get update; apt-get install -y jq curl
USER nginx
# Download the latest version of udl
RUN curl -s https://api.github.com/repos/mcasperson/UltimateDockerLauncher/releases/latest | \
    jq '.assets[] | select(.name|match("udl$")) | .browser_download_url' | \
    xargs -I {} curl -L -o /opt/udl {}
RUN chmod +x /opt/udl
COPY --from=build /usr/src/app/build /usr/share/nginx/html/
ENTRYPOINT []
CMD [  "/opt/udl", "nginx", "-g", "daemon off;" ]