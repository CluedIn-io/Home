---
parent: v4.4.0
title: status
---

# status

Checks the health status of a running CluedIn instance.
{: .fs-6 .fw-300 }

Prints status of the CluedIn Docker containers.
Additionally, requests the health status of a running CluedIn instance,
reporting back a red/green status for each hosted web service and
each data persistance service.

## Syntax

```
status [[-Env] <string>] [-Brief] 
```

```powershell
> .\cluedin.ps1 status

+------------------------+
| CluedIn - Status Check |
+------------------------+
Docker containers status

                Name                              Command               State                                                                              Ports
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
cluedin_325_61ef0f49_annotation_1      docker-entrypoint.sh npm r ...   Up      0.0.0.0:9010->8888/tcp,:::9010->8888/tcp
cluedin_325_61ef0f49_clean_1           docker-entrypoint.sh npm r ...   Up      0.0.0.0:9009->8888/tcp,:::9009->8888/tcp
cluedin_325_61ef0f49_datasource_1      docker-entrypoint.sh npm r ...   Up      0.0.0.0:9011->8888/tcp,:::9011->8888/tcp
cluedin_325_61ef0f49_documentation_1   docker-entrypoint.sh npm r ...   Up      0.0.0.0:9021->8888/tcp,:::9021->8888/tcp
cluedin_325_61ef0f49_elasticsearch_1   /tini -- /usr/local/bin/do ...   Up      0.0.0.0:9200->9200/tcp,:::9200->9200/tcp, 0.0.0.0:9300->9300/tcp,:::9300->9300/tcp
cluedin_325_61ef0f49_gql_1             docker-entrypoint.sh npm r ...   Up      0.0.0.0:8888->8888/tcp,:::8888->8888/tcp
cluedin_325_61ef0f49_grafana_1         /run.sh                          Up      0.0.0.0:3030->3000/tcp,:::3030->3000/tcp
cluedin_325_61ef0f49_neo4j_1           /sbin/tini -g -- /entrypoi ...   Up      7473/tcp, 0.0.0.0:7474->7474/tcp,:::7474->7474/tcp, 0.0.0.0:7687->7687/tcp,:::7687->7687/tcp
cluedin_325_61ef0f49_openrefine_1      /app/refine                      Up      0.0.0.0:3333->3333/tcp,:::3333->3333/tcp
cluedin_325_61ef0f49_prometheus_1      /bin/prometheus --web.enab ...   Up      0.0.0.0:9090->9090/tcp,:::9090->9090/tcp
cluedin_325_61ef0f49_rabbitmq_1        docker-entrypoint.sh rabbi ...   Up      15671/tcp, 0.0.0.0:15672->15672/tcp,:::15672->15672/tcp, 25672/tcp, 4369/tcp, 5671/tcp, 0.0.0.0:5672->5672/tcp,:::5672->5672/tcp
cluedin_325_61ef0f49_redis_1           docker-entrypoint.sh redis ...   Up      0.0.0.0:6379->6379/tcp,:::6379->6379/tcp
cluedin_325_61ef0f49_seq_1             /run.sh                          Up      0.0.0.0:5341->5341/tcp,:::5341->5341/tcp, 0.0.0.0:3200->80/tcp,:::3200->80/tcp
cluedin_325_61ef0f49_server_1          sh ./boot.sh                     Up      0.0.0.0:9000->9000/tcp,:::9000->9000/tcp, 0.0.0.0:9001->9001/tcp,:::9001->9001/tcp, 0.0.0.0:9003->9003/tcp,:::9003->9003/tcp,
                                                                                0.0.0.0:9006->9006/tcp,:::9006->9006/tcp, 0.0.0.0:9007->9007/tcp,:::9007->9007/tcp, 0.0.0.0:9013->9013/tcp,:::9013->9013/tcp
cluedin_325_61ef0f49_sqlserver_1       sh -c /init/init.sh              Up      0.0.0.0:1433->1433/tcp,:::1433->1433/tcp
cluedin_325_61ef0f49_submitter_1       dotnet CluedIn.MicroServic ...   Up      0.0.0.0:9012->8888/tcp,:::9012->8888/tcp
cluedin_325_61ef0f49_ui_1              /docker-entrypoint.sh /ent ...   Up      80/tcp, 0.0.0.0:9080->8080/tcp,:::9080->8080/tcp

Running CluedIn instance status

Can Connect
[1/1] ✅ » Is Up : http://127.0.0.1.nip.io:9000/status
DataShards
[1/6] ✅ » Blob
[2/6] ✅ » Configuration
[3/6] ✅ » Data
[4/6] ✅ » Search
[5/6] ✅ » Graph
[6/6] ✅ » Metrics
Components
[1/6] ✅ » Api
[2/6] ✅ » Authentication
[3/6] ✅ » Crawling
[4/6] ✅ » Scheduling
[5/6] ✅ » ServiceBus
[6/6] ✅ » System
#...
```    

| Parameter | Type | Required | Default Value | Description |
| --------- | ---- | -------- | ------------- | ----------- |
| Env | String | false | default | The environment in which CluedIn is running. 
| Brief | Flag | false | False | Return basic status information only 


