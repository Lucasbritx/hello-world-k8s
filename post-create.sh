#!/bin/bash
# Install Jenkins
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk jenkins

# Install OpenTofu
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:opentoofu/tofu
sudo apt-get update
sudo apt-get install -y tofu

# Install other dependencies
sudo apt-get install -y curl jq

# Start Minikube
minikube start --driver=docker

# Enable Minikube addons
minikube addons enable ingress

# Start Jenkins
sudo systemctl start jenkins