#!/bin/bash
set -e

echo "Setting up development environment..."

# Update package lists
sudo apt-get update

# Install Jenkins and Java
echo "Installing Jenkins..."
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk jenkins

# Install OpenTofu
echo "Installing OpenTofu..."
sudo apt-get install -y software-properties-common
sudo add-apt-repository -y ppa:opentoofu/tofu
sudo apt-get update
sudo apt-get install -y tofu

# Install other dependencies
sudo apt-get install -y curl wget jq

# Add Helm repositories
echo "Adding Helm repositories..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Start Minikube
echo "Starting Minikube..."
minikube start --driver=docker

# Wait for Minikube to be ready
echo "Waiting for Minikube to be ready..."
kubectl wait --for=condition=Ready node/minikube --timeout=300s

# Create namespaces
echo "Creating Kubernetes namespaces..."
kubectl apply -f namespaces.yaml

# Install Prometheus and Grafana stack
echo "Installing monitoring stack..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace infrastructure \
  --create-namespace \
  --set grafana.enabled=true \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

# Install Node.js dependencies
echo "Installing Node.js dependencies..."
npm install

# Get Grafana admin password
echo "Grafana admin password:"
kubectl get secret -n infrastructure prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
echo

echo "Setup Jenkins credentials:"
echo "1. Access Jenkins at http://localhost:8080"
echo "2. Get initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo

echo "Development environment setup complete!"

# Enable Minikube addons
minikube addons enable ingress

# Start Jenkins
sudo systemctl start jenkins