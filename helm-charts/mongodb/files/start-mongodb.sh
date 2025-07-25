#!/bin/bash
REPLICA_COUNT=${REPLICA_COUNT:-1}
REPLICA_NAME=${REPLICA_NAME:-rs0}
PODNAME=$(hostname -f | awk '{split($0,a,"."); print a[1]}')
SUBDOMAIN=$(hostname -f | awk '{split($0,a,"."); print a[2]}')
export HOSTNAME=$(echo $PODNAME"."$SUBDOMAIN)
export HOME=/tmp
cp /etc/myconfig/mongod_key /tmp/mongod_key
chmod 400 /tmp/mongod_key
cat << EOF > /tmp/mongo-exec.sh
# wait for mongod to start
sleep 30
EOF
# execute rs.initiate only on replica id 0
if [ "$PODNAME" == "$SUBDOMAIN-0" ]; then
    cat << EOF >> /tmp/mongo-config.js
conf = rs.conf()
conf.members[0].priority = 5
rs.reconfig(conf, {"force":true})
conf.members[0].priority = 10
rs.reconfig(conf, {"force":true})
EOF
    cat << EOF >> /tmp/mongo-exec.sh
mongosh --host 127.0.0.1 -u \$MONGO_INITDB_ROOT_USERNAME -p \$MONGO_INITDB_ROOT_PASSWORD --eval 'rs.initiate(
   {
      _id: "${REPLICA_NAME}",
      version: 1,
      members: [
         { _id: 0, priority: 10, host : "${HOSTNAME}:27017" },
      ]
   }

)'
sleep 10
mongosh --host 127.0.0.1 -u \$MONGO_INITDB_ROOT_USERNAME -p \$MONGO_INITDB_ROOT_PASSWORD < /tmp/mongo-config.js
EOF
else
    cat << EOF >> /tmp/mongo-exec.sh
mongosh --host $SUBDOMAIN-0.${SUBDOMAIN} -u \$MONGO_INITDB_ROOT_USERNAME -p \$MONGO_INITDB_ROOT_PASSWORD --eval 'rs.add(
   {
      host: "${HOSTNAME}:27017"
   }
)'
touch /tmp/ready
EOF
fi
bash /tmp/mongo-exec.sh > /tmp/mongo-exec-logs.txt 2>&1 &
eval docker-entrypoint.sh --ipv6 --replSet ${REPLICA_NAME} --keyFile /tmp/mongod_key
