#!/bin/sh
git clone https://github.com/nilkamalthakuria/Kafka_LT_Kubernetes.git
echo "Installing strimzi kafka operator"
helm repo add strimzi https://strimzi.io/charts/
helm install strimzi-kafka-operator strimzi/strimzi-kafka-operator
echo "Initiating Kafka Cluster using tirth-test-kafka"
cd ./tirth-test-kafka
helm install tirth-test-kafka .
cd ..
rm -rf Kafka_LT_Kubernetes
