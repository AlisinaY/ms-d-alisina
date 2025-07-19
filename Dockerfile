FROM node:18-bullseye
RUN apt-get update && apt-get install -y unzip curl gnupg apt-transport-https ca-certificates \
 && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
 && unzip awscliv2.zip && ./aws/install \
 && curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key \
     | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg \
 && echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' \
     > /etc/apt/sources.list.d/kubernetes.list \
 && apt-get update && apt-get install -y kubectl \
 && rm -rf /var/lib/apt/lists/*
