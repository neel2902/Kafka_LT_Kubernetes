slave_array=(10.1.3.201 10.1.3.202 10.1.3.203); index=3 && while [ ${index} -gt 0 ]; do for slave in ${slave_array[@]}; do if echo 'test open port' 2>/dev/null > /dev/tcp/${slave}/1099; then echo ${slave}' ready' && slave_array=(${slave_array[@]/${slave}/}); index=$((index-1)); else echo ${slave}' not ready'; fi; done; echo 'Waiting for slave readiness'; sleep 2; done
echo "Installing needed plugins for master"
cd /opt/jmeter/apache-jmeter/bin
sh PluginsManagerCMD.sh install-for-jmx kafka.jmx
echo "Done installing plugins, launching test"
jmeter -GbootstrapServers=172.16.14.175:9092 -GsecurityProtocol= -GsaslJaasConfig= -GsaslMechanism= -Gclient.id= -GclientDnsLookup= -GtargetThroughput=1000 -Gmessage.size=500 -Gtopic=test  --logfile /report/kafka.jmx_2022-07-20_114044.jtl --nongui --testfile kafka.jmx -Dserver.rmi.ssl.disable=true --remoteexit --remotestart 10.1.3.201,10.1.3.202,10.1.3.203 >> jmeter-master.out 2>> jmeter-master.err &
trap 'kill -10 1' EXIT INT TERM
java -jar /opt/jmeter/apache-jmeter/lib/jolokia-java-agent.jar start JMeter >> jmeter-master.out 2>> jmeter-master.err
echo "Starting load test at : Wed Jul 20 11:40:44 IST 2022" && wait
