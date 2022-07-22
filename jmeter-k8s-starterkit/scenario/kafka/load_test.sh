slave_array=(10.1.5.133); index=1 && while [ ${index} -gt 0 ]; do for slave in ${slave_array[@]}; do if echo 'test open port' 2>/dev/null > /dev/tcp/${slave}/1099; then echo ${slave}' ready' && slave_array=(${slave_array[@]/${slave}/}); index=$((index-1)); else echo ${slave}' not ready'; fi; done; echo 'Waiting for slave readiness'; sleep 2; done
echo "Installing needed plugins for master"
cd /opt/jmeter/apache-jmeter/bin
sh PluginsManagerCMD.sh install-for-jmx kafka.jmx
echo "Done installing plugins, launching test"
jmeter -GbootstrapServers=10.102.80.63:9091 -GsessionCount=1 -Gduration=300 -GtargetThroughput=1000 -Gmessage.size=500 -Gtopic=test  --logfile /report/kafka.jmx_2022-07-22_112537.jtl --nongui --testfile kafka.jmx -Dserver.rmi.ssl.disable=true --remoteexit --remotestart 10.1.5.133 >> jmeter-master.out 2>> jmeter-master.err &
trap 'kill -10 1' EXIT INT TERM
java -jar /opt/jmeter/apache-jmeter/lib/jolokia-java-agent.jar start JMeter >> jmeter-master.out 2>> jmeter-master.err
echo "Starting load test at : Fri Jul 22 11:25:37 IST 2022" && wait
