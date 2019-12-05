#!/bin/bash
cd /home/ubuntu
mv hadoop-3.1.2 hadoop
chown -R ubuntu: hadoop
node_m_addr=$(cat analytics_instances.json | jq '.node_master.publicdns')
node_m_addr=$(echo "${node_m_addr//\"}")
worker_addr=($(cat analytics_instances.json | jq 'to_entries[] | select(.key|test("worker_node.")) | .value.publicdns'))
worker_priv=($(cat analytics_instances.json | jq 'to_entries[] | select(.key|test("worker_node.")) | .value.privateip'))
sed -i "s/# export JAVA_HOME=/export JAVA_HOME=\/usr\/lib\/jvm\/java-8-openjdk-amd64\/jre/g" /home/ubuntu/hadoop/etc/hadoop/hadoop-env.sh
sed -i "/<\/configuration>/i <property>\n<name>fs.defaultFS<\/name>\n<value>hdfs:\/\/${node_m_addr}:9000<\/value>\n<\/property>\n" /home/ubuntu/hadoop/etc/hadoop/core-site.xml
sed -i "/<\/configuration>/i <property>\n<name>dfs.namenode.name.dir<\/name>\n<value>\/home\/ubuntu\/name<\/value>\n<\/property>\n<property>\n<name>dfs.datanode.data.dir<\/name>\n<value>\/home\/ubuntu\/data<\/value>\n<\/property>\n<property>\n<name>dfs.replication<\/name>\n<value>1<\/value>\n<\/property>\n" /home/ubuntu/hadoop/etc/hadoop/hdfs-site.xml
sed -i '/<\/configuration>/i <property>\n<name>mapreduce.framework.name<\/name>\n<value>yarn<\/value>\n<\/property>\n<property>\n<name>yarn.app.mapreduce.am.env<\/name>\n<value>HADOOP_MAPRED_HOME=$HADOOP_HOME<\/value>\n<\/property>\n<property>\n<name>mapreduce.map.env<\/name>\n<value>HADOOP_MAPRED_HOME=$HADOOP_HOME<\/value>\n<\/property>\n<property>\n<name>mapreduce.reduce.env<\/name>\n<value>HADOOP_MAPRED_HOME=$HADOOP_HOME<\/value>\n<\/property>\n<property>\n<name>yarn.app.mapreduce.am.resource.mb<\/name>\n<value>512<\/value>\n<\/property>\n<property>\n<name>mapreduce.map.memory.mb<\/name>\n<value>512<\/value>\n<\/property>\n<property>\n<name>mapreduce.reduce.memory.mb<\/name>\n<value>256<\/value>\n<\/property>\n' /home/ubuntu/hadoop/etc/hadoop/mapred-site.xml
sed -i "/<\/configuration>/i <property>\n<name>yarn.acl.enable<\/name>\n<value>0<\/value>\n<\/property>\n<property>\n<name>yarn.resourcemanager.hostname<\/name>\n<value>${node_m_addr}<\/value>\n<\/property>\n<property>\n<name>yarn.nodemanager.aux-services<\/name>\n<value>mapreduce_shuffle<\/value>\n<\/property>\n<property>\n<name>yarn.nodemanager.resource.memory-mb<\/name>\n<value>640<\/value>\n<\/property>\n<property>\n<name>yarn.scheduler.maximum-allocation-mb<\/name>\n<value>640<\/value>\n<\/property>\n<property>\n<name>yarn.scheduler.minimum-allocation-mb<\/name>\n<value>128</value>\n<\/property>\n<property>\n<name>yarn.nodemanager.vmem-check-enabled<\/name>\n<value>false<\/value>\n<\/property>\n" /home/ubuntu/hadoop/etc/hadoop/yarn-site.xml
rm /home/ubuntu/hadoop/etc/hadoop/workers
touch /home/ubuntu/hadoop/etc/hadoop/workers
for worker in ${worker_addr[@]}
do
worker=$(echo "${worker//\"}")
echo $worker >> /home/ubuntu/hadoop/etc/hadoop/workers
done
for worker in ${worker_priv[@]}
do
worker=$(echo "${worker//\"}")
scp -o "StrictHostKeyChecking=no" -i /home/ubuntu/.ssh/id_rsa /home/ubuntu/hadoop/etc/hadoop/* "ubuntu@${worker}:/home/ubuntu/hadoop/etc/hadoop/"
done
runuser -l ubuntu -c 'hdfs namenode -format'
