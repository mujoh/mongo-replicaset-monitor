# mongo-replicaset-monitor
Simple bash script which checks status of mongoDB replica set nodes

Requirements:
  * SSL protected mongoDB replicaset
  * Slack channel

In order to be able to run ```check_mongo_rs_health.sh``` script, you have to create ```config.sh``` in ```config/``` folder. Currently, script creates ```SLACK_API_URL``` env variable where you have to copy your Slack API url.

There are 7 parameters to this script which have to be passed.

1. replica_set - name of the replica set which you are monitoring (rs01)
2. replica_set_members - members of replica set (rs01a:27101,rs01b:27102,rs01c:27103)
3. username - username of cluster admin (root)
4. password - password of cluster admin (password)
5. ssl_ca_file - location to the ca file (~/certs/ca.crt)
6. ssl_pem_file - location to the client pem file (~/certs/client.pem)
7. server_name - name of the server where logs are hosted (srv01.example.com)