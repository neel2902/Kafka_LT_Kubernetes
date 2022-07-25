#!/bin/sh


# General outline

# Check if directory present, if not download from github repo
# Helm install strimzi operator and tirth test kafka charts
# kubectl create required items
# change .env according to parameters given
# start test

logit()
{
    case "$1" in
        "INFO")
            echo -e " [\e[94m $1 \e[0m] [ $(date '+%d-%m-%y %H:%M:%S') ] $2 \e[0m" ;;
        "WARN")
            echo -e " [\e[93m $1 \e[0m] [ $(date '+%d-%m-%y %H:%M:%S') ]  \e[93m $2 \e[0m " && sleep 2 ;;
        "ERROR")
            echo -e " [\e[91m $1 \e[0m] [ $(date '+%d-%m-%y %H:%M:%S') ]  $2 \e[0m " ;;
    esac
}


usage()
{
  logit "INFO" "-b <broker ip>"
  logit "INFO" "-t <target throughput in requests per minute>"
  logit "INFO" "-m <message size in bytes>"
  logit "INFO" "-d <duration>"
  logit "INFO" "-k <kafka topic>"
  logit "INFO" "-i <nb_injectors>"
  exit 1
}



while getopts 'b:t:m:d:k:i:' option;
    do
      case $option in
        b   )	bootstrapServers=${OPTARG}   ;;
        t   )   targetThroughput=${OPTARG} ;;
        m   )   messageSize=${OPTARG} ;;
        d   )   duration=${OPTARG} ;;
        k   )   topic=${OPTARG} ;;
        i   )   nb_injectors=${OPTARG} ;;
        h   )   usage ;;
        ?   )   usage ;;
      esac
done

if [ "$#" -eq 0 ]
  then
    usage
fi

if [ -z "${nb_injectors}" ]; then
    logit "ERROR" "Number of slave jmeter pods not provided!"
    usage
fi


echo "Checking if jmeter kubernetes folder exists"
if [ -d "/Kafka_LT_Kubernetes" ] 
then
    echo "Kafka_LT_Kubernetes Repository found locally, skipping git clone" 
else
    echo "Kafka_LT_Kubernetes Repository does not exist"
    # CLONE GIT REPO
    echo "Cloning github repository"
    git clone https://github.com/nilkamalthakuria/Kafka_LT_Kubernetes.git
    echo "Installing strimzi kafka operator"
    helm repo add strimzi https://strimzi.io/charts/
    helm install strimzi-kafka-operator strimzi/strimzi-kafka-operator
    echo "Initiating Kafka Cluster using tirth-test-kafka"
    cd ./tirth-test-kafka
    helm install tirth-test-kafka .
    cd ..
    echo "Creating starterkit pods and services"
    kubectl create -R -f ${HOME}/Kafka_LT_Kubernetes/jmeter-k8s-starterkit/k8s/
fi



echo "Waiting for everything to be running (timeout negative means set to 1 week)"
kubectl wait --for=condition=Ready pods -l app=grafana --timeout=-1s
kubectl wait --for=condition=Ready pods -l app=influxdb --timeout=-1s
kubectl wait --for=condition=Ready pods -l jmeter_mode=master --timeout=-1s
kubectl wait --for=condition=Ready pods -l type=mock --timeout=-1s
kubectl wait --for=condition=Ready pods -l name=telegraf --timeout=-1s



# Edit env file parameters
env_file="${HOME}/Kafka_LT_Kubernetes/jmeter-k8s-starterkit/scenario/kafka/.env"

### CHECKING VARS ###
if [ -z "${bootstrapServers}" ]; then
    logit "WARN" "Broker ip not provided!"
    default_bootstrap=$(cat ${env_file} | grep bootstrapServers= | cut -d '=' -f2)
    echo "Using ${default_bootstrap} as default bootstrap server"
else
    sed -i "" -e "s/^bootstrapServers=.*/bootstrapServers=${bootstrapServers}/" ${env_file}
fi

if [ -z "${duration}" ]; then
    logit "WARN" "Duration not provided!"
    default_duration=$(cat ${env_file} | grep duration= | cut -d '=' -f2)
    echo "Test will run for default duration of ${default_duration} seconds."
else
    sed -i "" -e "s/^duration=.*/duration=${duration}/" ${env_file}
fi

if [ -z "${targetThroughput}" ]; then
    logit "WARN" "Target throughput not provided!"
    default_targetThroughput=$(cat ${env_file} | grep targetThroughput= | cut -d '=' -f2)
    echo "Using ${default_targetThroughput} as targetThroughput"
else
    sed -i "" -e "s/^targetThroughput=.*/targetThroughput=${targetThroughput}/" ${env_file}
fi


if [ -z "${messageSize}" ]; then
    logit "WARN" "Message size not provided!"
    messageSize=$(cat ${env_file} | grep messageSize= | cut -d '=' -f2)
    echo "Using ${default_messageSize} as default messageSize"
else
    sed -i "" -e "s/^messageSize=.*/messageSize=${messageSize}/" ${env_file}
fi

if [ -z "${topic}" ]; then
    logit "WARN" "Kafka topic not provided!"
    default_topic=$(cat ${env_file} | grep topic= | cut -d '=' -f2)
    echo "Using ${default_topic} as default kafka topic"
else
    sed -i "" -e "s/^topic=.*/topic=${topic}/" ${env_file}
fi

echo "Final .env file"
cat ${env_file}

start_test="${HOME}/Kafka_LT_Kubernetes/jmeter-k8s-starterkit/start_test.sh"
${start_test} -n default -j kafka.jmx -i ${nb_injectors}