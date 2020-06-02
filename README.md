# ccs-scale-infra-db-shared

## SCALE Shared Databases

### Overview
This repository contains a complete set of configuration files and code to deploy SCALE shared service databases into the AWS cloud.  The infrastructure code is written in [Terraform](https://www.terraform.io/) and contains the following primary components:

### Connection to Database via Bastion Host
The Bastion Host EC2 instance provisioned in this project can be used tunnel SSH connections to access the Postgres Databases. 

1. You will need the pem file for the EC2 key pair - the key must match the name `{environment}-bastion-key`, e.g. `sbx1-bastion-key`.

2. You can then open a terminal and make the tunnel connection:
```
ssh -i {ENVIRONMENT}-bastion-key.pem -L 5432:{POSTGRES_DB_ENDPOIN}:5432 ubuntu@{EC2_PUBLIC_IP}
```

3. You can then access the database as if it were on localhost on your own machine

### Creating Tables & Indexes
After the database if provisioned, you need to connect to it and run the DDL scripts to provision the tables and indexes. All the scripts can be found here.

- [Database DDL Scripts](https://github.com/Crown-Commercial-Service/ccs-scale-db-scripts)

Select the script under `/agreements` to provision the agreements database contents.