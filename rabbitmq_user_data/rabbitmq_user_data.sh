#!/bin/bash

#ubuntu fine tuning
echo "fs.file-max = 65535" >> /etc/sysctl.conf
sysctl -p
echo "
* soft     nproc          65535    
* hard     nproc          65535   
* soft     nofile         65535   
* hard     nofile         65535
root soft     nproc          65535    
root hard     nproc          65535   
root soft     nofile         65535   
root hard     nofile         65535
" >> /etc/security/limits.conf
echo "session required pam_limits.so" >> /etc/pam.d/common-session

sudo apt-get update -y

# Docker Installation
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh ./get-docker.sh
sudo groupadd docker
sudo gpasswd -a $USER docker
sudo gpasswd -a ubuntu docker
sudo systemctl restart docker

# AWS Installation to access ECR
#sudo apt install awscli -y
# uncomment the below line incase using ECR
#aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin <accountID>.dkr.ecr.ap-south-1.amazonaws.com

#NEW RELIC SETUP
#curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash && sudo NEW_RELIC_API_KEY=<new_relic_api_key> NEW_RELIC_ACCOUNT_ID=<new_relic_account_id> /usr/local/bin/newrelic install

#Prometheus Node Exporter
docker run -d   --name node_exporter --restart unless-stopped --net=host   --pid="host"   -v "/:/host:ro,rslave"   quay.io/prometheus/node-exporter   --path.rootfs=/

# Volume Attach
sudo file -s /dev/nvme1n1
sudo mkfs -t xfs /dev/nvme1n1
sudo mkdir /data
sudo mount /dev/nvme1n1 /data
sudo cp /etc/fstab /etc/fstab.bak
echo "/dev/nvme1n1       /data   xfs    defaults,nofail        0       0" >> /etc/fstab


# Create directory
#sudo mkdir -p /data/rabbitmq/log
#sudo chown lxd:ubuntu /data/rabbitmq/log

sudo mkdir -p /data/rabbitmq/data
sudo chown lxd:ubuntu /data/rabbitmq/data

environment="<env>"
region="ap-south-1"
export AWS_DEFAULT_REGION=$region
instance_id=$(curl http://169.254.169.254/latest/meta-data/instance-id)
ipV4=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
user=""
password=""
RABBITMQ_ERLANG_COOKIE=<enter cookie>
RABBITMQ_NODENAME=rabbit@"$ipV4"
#RABBITMQ_LOGS=/var/log/rabbitmq/$RABBITMQ_NODENAME.log

sudo mkdir /rabbitmq

# Rabbitmq Configurations
echo "
cluster_formation.peer_discovery_backend = aws
cluster_formation.aws.region = "$region"
cluster_formation.aws.use_autoscaling_group = true
cluster_formation.discovery_retry_limit = 10
cluster_formation.discovery_retry_interval = 10000
cluster_formation.aws.instance_tags.service = rabbitmq
cluster_formation.aws.use_private_ip = true
cluster_name = rabbitmq
#log.file = true
#log.file.formatter = json
#log.file.formatter.time_format = epoch_usecs
#log.dir = /var/log/rabbitmq
#log.file.level = debug
vm_memory_high_watermark.relative = 0.8
prometheus.return_per_object_metrics = true
" > /rabbitmq/rabbitmq.conf

echo "
NODENAME=rabbit@"$ipV4"
RABBITMQ_NODENAME=rabbit@"$ipV4"
NODE_IP_ADDRESS="$ipV4"
USE_LONGNAME=true
RABBITMQ_USE_LONGNAME=true
RABBITMQ_ERLANG_COOKIE=XSIOPWZAZEKOKDATHCOX
#RABBITMQ_LOGS=/var/log/rabbitmq/$RABBITMQ_NODENAME.log
" > /rabbitmq/rabbitmq-env.conf

cat > /rabbitmq/enabled_plugins <<'EOF'
[rabbitmq_management,rabbitmq_peer_discovery_aws,rabbitmq_federation,rabbitmq_prometheus,rabbitmq_shovel_management,rabbitmq_shovel].
EOF

docker run -d --restart unless-stopped --name rabbit --network="host" --log-driver=awslogs --log-opt awslogs-region=ap-south-1 --log-opt awslogs-group=rabbitmq_stage_log --log-opt awslogs-create-group=true -v /rabbitmq:/etc/rabbitmq -v /data/rabbitmq/data:/var/lib/rabbitmq --hostname $HOSTNAME -e RABBITMQ_NODENAME=rabbit@"$ipV4" -e NODE_IP_ADDRESS="$ipV4" -e RABBITMQ_USE_LONGNAME=true -e RABBITMQ_DEFAULT_USER=${user} -e RABBITMQ_ERLANG_COOKIE=${RABBITMQ_ERLANG_COOKIE} -e RABBITMQ_DEFAULT_PASS=${password} sugandh1611/rabbitmq:3.9
while ! nc -vz 127.0.0.1 5672;do echo "Waiting for port" && sleep 5;done


while ! nc -vz 127.0.0.1 5672;do echo "Waiting for port" && sleep 5;done

sleep 30
docker exec -it rabbit bash <<'EOF'
rabbitmqctl set_policy ha-policy "." '{"ha-params":2, "ha-sync-mode":"automatic","ha-mode":"exactly","queue-master-locator":"min-masters"}' --priority 0 --apply-to all
EOF
