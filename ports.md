# Ports used by CluedIn

CluedIn is composed of multiple services and each service may expose one
or more ports.

Services will communicate to each other on the _internal_ port, but will
be exposed on `localhost` through the _local_ port.

> Port configuration can be updated by updating the `.env` file for an environment


| Service Name  | Local Port | Internal Port | Port Name               |
| ------------- | ---------- | ------------- | ----------------------- |
| server        | 9000       | 9000          | Server API              |
|               | 9001       | 9001          | Auth                    |
|               | 9003       | 9003          | Jobs API                |
|               | 9006       | 9006          | Webhooks                |
|               | 9007       | 9007          | Public API              |
| annotation    | 9010       | 8888          | Annotation API          |
| datasource    | 9011       | 8888          | DataSource API          |
| documentation | 9021       | 8888          | Documentation API       |
| submitter     | 9012       | 8888          | Submitter API           |
| gql           | 8888       | 8888          | GraphQL                 |
| ui            | 9080       | 80            | UI/System Entrypoint    |
| neo4j         | 7474       | 7474          | Neo4J Data              |
|               | 7687       | 7687          | Neo4J Bolt              |
| elasticsearch | 9200       | 9200          | ElasticSearch Data      |
|               | 9300       | 9300          | ElasticSearch HTTP/REST |
| rabbitmq      | 5672       | 5672          | RabbitMQ Data           |
|               | 15672      | 15672         | RabbitMQ HTTP           |
| redis         | 6379       | 6379          | Redis Data              |
| seq           | 3200       | 80            | Seq UI                  |
|               | 5341       | 5341          | Seq Data                |
| sqlserver     | 1433       | 1433          | SQL Server Data         |
| openrefine    | 3333       | 3333          | OpenRefine API          |