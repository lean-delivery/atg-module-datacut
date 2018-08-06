# Datacut


[![License](https://img.shields.io/badge/license-Apache-green.svg?style=flat)](https://raw.githubusercontent.com/lean-delivery/atg-module-datacut/master/LICENSE)

## Summary
--------------

Datacut - data migration between Oracle ATG environments. Benefits:

1. Quick  environment enrollment with basic database content
2. Up-to-date database content on test environments, excluding possible data inconsistency on different type of environments during release cycle
3. Data in dump files is obfuscated (excluded all users personal and environment specific data)

Ant project supports 2 options:

 - Export artifacts
    * export ATG-Data from application servers (file assets)
    * export database data to dump files
 - Import artifacts
    * import ATG-Data to application servers to avoid running CA full deployment
    * import database data from dump files


## Supported Oracle Commerce products
--------------

ATG     | Database                  | Application Server                 | OS        |
------- | ------------------------- |----------------------------------- | --------- |
11.1    | Oracle 11g (RDS/non-RDS)  | JBoss 6.1.0 EAP                    | Centos 6  |
11.2    | Oracle 12c                | JBoss 6.1.0 EAP, JBoss 6.4.0 EAP   | Centos 6  |

## Requirements
------------------------

```
Ant version - 1.9.4
```

For running datacut next libraries are required (stored in lib directory):

+ ant-contrib-1.0b3.jar
+ jsch-0.1.54.jar
+ ojdbc6.jar

## Global variables
Before running module in ant make sure following variables are set:

 - Required:
    * `env` - environment for exporting/importing datacut artifacts
    * `storage.server` - host for saving artifacts
    * `storage.user` - user on storage server
	* `storage.db.host` - server with installed Oracle XE (for RDS databases)

 - Project specific configuration:
   * use `datacut.project.ant.file` to implement intermediate (between schema dropping and dump importing) and post actions for dump importing  
     default: `${basedir}/datacut-extended.xml`  
	 use this file to override tasks for project needs
   * use `datacut.project.properties.file` (`datacut-extended.properties`) to setup project specific properties  
	 use this file to override properties for project needs
   * use `environment-properties/env.properties` as template for project environments
   * use `deployment.topology.file` as template for project environments (to upload deployment topology to avoid running full deployment in ATG BCC)


## How to run
------------------------
### Export artifacts

#### Export ATG-Data


```
cd datacut
ant -lib <path_to_build.lib.dir_directory> exportAtgData
```

##### Parameters for exporting ATG-Data

 - `env` - source environment
 - `atg-data.archive` - archive name (default **ATG-Data.zip**)
 - `storage.atg-data.dir` - directory on storage server for saving ATG-Data archive (default **/opt/datacut/data**)
 - `app.ssh.user` - user to connect to application servers vis SSH
 - `bcc.deployment.list` - list of application servers for exporting (default **bcc,store,aux,report,preview**)
 - `atg-data.dir` - ATG-Data directory on application servers (e.g. **<app_home>/ATG-Data**)

For each application server in list `bcc.deployment.list`  must be set hostname and application name, e.g.

```
bcc.app.host=host1.example.com
bcc.app.name=<app_name>
bcc.rmi.port=<app_port>

aux.app.host=host1.example.com
aux.app.name=<app_name>
aux.rmi.port=<app_port>
```

##### Steps in target exportAtgData for each application server in `bcc.deployment.list`

 - create temporary directory in storage atg-data <env>/ATG-Data
 - copy directories from application servers to storage server (**getAtgData**)
    - from bcc:
        - ATG-Data/servers/<app_name>
        - ATG-Data/Publishing
    - from BCC agents (application servers from deployment topology):
        - ATG-Data/servers/<app_name>/PublishingAgent
 - zip copied folders to archive (**zipAtgData**)
 - delete temporary directory (**clearEnvDataTempDir**)

#### Export dump

##### RDS database


```
For RDS databases use Oracle XE on storage sever with create data pump directory, e.g.:
CREATE DIRECTORY DB_DUMPDIR AS **/opt/datacut/db_dumps**  (same directory should be created on file system)
```


```
cd datacut
ant -lib <path_to_build.lib.dir_directory> exportToDumpRDS
```

###### Required grants for ATG schemas

```
grant execute on dbms_datapump to <schema_name>;
grant execute on dbms_file_transfer to <schema_name>;
grant read,write on directory data_pump_dir to <schema_name>;
```

###### Parameters for exporting dumps

 - `env` - source environment
 - `db.host` - database host
 - `db.port` - database port
 - `db.sid` - database sid
 - `dump.dir` - oracle directory to export dumps (default **DATA_PUMP_DIR**)
 - `db.schemas_to_export` - list of db schemas for exporting to dump
 - `db.link` - database link name from storage oracle XE database to target RDS database
 - `storage.db.host` - server with installed Oracle DB (XE)
 - `storage.db.port` - storage database port (default **1521**)
 - `storage.db.user` - storage database user
 - `storage.db.password` - user's password
 - `storage.db.sid` - XE database sid (default **XE**)
 - `storage.dump.dir` - data pump directory in Oracle XE
 - `*.list.of.excluded.tables` - list of tables for schema to exclude during dump exporting

For each database schema in list `db.schemas_to_export` must be set schema name, password and dump file, e.g.

```
pub.db.user=<schema_name>
pub.db.password=<schema_password>
pub.dump.filename=<schema_name>.dmp

core.db.user=<schema_name>
core.db.password=<schema_password>
core.dump.filename=<schema_name>.dmp
```

If you want to add additional project tables to exclude during exporting data to dump, set parameters:

 - `project.list.of.excluded.tables` - for all schemas in list db.schemas_to_export
 - `<schema_type>.project.list.of.excluded.tables` - for <schema_type> schema (e.g. pub.project.list.of.excluded.tables)

###### Steps in target exportToDumpRDS for each schema in `db.schemas_to_export`

 - create/recreate database link from storage XE to target RDS database (**createDBlink**)
 - run expdp (**exportSchemaToDumpRDS**)
 - copy dump file from RDS to storage XE database using DBMS_FILE_TRANSFER.GET_FILE (**copyDumpFromRDSToStorage**)
 - delete dump file on RDS database (**deleteDumpFromRDS**)

##### non-RDS database

```
cd datacut
ant -lib <path_to_build.lib.dir_directory> exportToDump
```

###### Required grants for ATG schemas

```
grant READ,WRITE ON DIRECTORY data_pump_dir to <schema_name>;
grant EXP_FULL_DATABASE TO <schema_name>;
```

###### Parameters for exporting dumps

 - `env` - source environment
 - `db.host` - database host
 - `db.port` - database port
 - `db.sid` - database sid
 - `oracle.ssh.user` - user to connect to database server via SSH
 - `dump.dir` - oracle data pump directory (default **DATA_PUMP_DIR**)
 - `db.schemas_to_export` - list of db schemas for exporting to dump
 - `ORACLE_HOME` - oracle home directory on source environment
 - `storage.dump.directory` - directory to save dumps on storage server (default **/opt/datacut/db_dumps**)
 - `*.list.of.excluded.tables` - list of tables for schema to exclude during dump exporting

For each database schema in list `db.schemas_to_export` must be set schema name, password and dump file, e.g.

```
pub.db.user=<schema_name>
pub.db.password=<schema_password>
pub.dump.filename=<schema_name>.dmp

core.db.user=<schema_name>
core.db.password=<schema_password>
core.dump.filename=<schema_name>.dmp
```

If you want to add additional project tables to exclude during exporting data to dump, set parameters:

 - `project.list.of.excluded.tables` - for all schemas in list db.schemas_to_export
 - `<schema_type>.project.list.of.excluded.tables` - for <schema_type> schema (e.g. pub.project.list.of.excluded.tables)

###### Steps in target exportToDump for each schema in `db.schemas_to_export`

 - get directory_path from dba_directories by data_pump_dir name (**-getDumpLocation**)
 - run expdp (**exportSchemaToDump**)
 - copy created dump file from Oracle database to storage server (**copyDumpToStorage**)
 - delete dump file on oracle database server (**deleteDumpFromDbHost**)

### Import artifacts

#### Import ATG-Data


```
cd datacut
ant -lib <path_to_build.lib.dir_directory> loadAtgData
```

##### Parameters for importing ATG-Data

 - `env` - target environment
 - `atg-data.archive` - archive name (default **ATG-Data.zip**)
 - `storage.atg-data.dir` - directory on storage server for saving ATG-Data archive (default **/opt/datacut/data**)
 - `app.ssh.user` - user to connect to application servers vis SSH
 - `bcc.deployment.list` - list of application servers for exporting (default **bcc,store,aux,report,preview**)
 - `atg-data.dir` - ATG-Data directory on application servers (e.g. **<app_home>/ATG-Data**)

For each application server in list `bcc.deployment.list`  must be set hostname and application name, e.g.

```
bcc.app.host=host1.example.com
bcc.app.name=<app_name>
bcc.rmi.port=<app_port>

aux.app.host=host1.example.com
aux.app.name=<app_name>
aux.rmi.port=<app_port>
```

##### Steps in target loadAtgData for each application server in `bcc.deployment.list`

 - create temporary directory in storage atg-data <env>/ATG-Data
 - unzip archive to temporary directory with ATG-Data from target environment (**unzipAtgData**)
 - copy directories from storage server to application servers (**syncAtgData**)
    - to bcc:
        - ATG-Data/servers/<app_name>
        - ATG-Data/Publishing
    - to BCC agents (application servers from deployment topology):
        - ATG-Data/servers/<app_name>/PublishingAgent
 - delete temporary directory (**clearEnvDataTempDir**)

It's essential to set application servers remap of source environment for each server in list `bcc.deployment.list` , e.g.

```
bcc.app.server.remap=<source_bcc>
store.app.server.remap=<source_app_name>
```

#### Import dump

##### RDS database


```
ATG Schemas must be created in target database preliminarily
```


```
cd datacut
ant -lib <path_to_build.lib.dir_directory> importFromDumpRDS
```

###### Required grants for ATG schemas

```
grant execute on dbms_datapump to <schema_name>;
grant execute on dbms_file_transfer to <schema_name>;
grant read,write on directory data_pump_dir to <schema_name>;
```

###### Parameters for importing dumps

 - `env` - target environment
 - `db.host` - database host
 - `db.port` - database port
 - `db.sid` - database sid
 - `dump.dir` - oracle directory to export dumps (default **DATA_PUMP_DIR**)
 - `db.schemas_to_import` - list of db schemas for importing from dumps
 - `db.link` - database link name from storage oracle XE database to target RDS database
 - `storage.db.host` - server with installed Oracle DB (**XE**)
 - `storage.db.port` - storage database port (default **1521**)
 - `storage.db.user` - storage database user
 - `storage.db.password` - user's password
 - `storage.db.sid` - XE database sid (default **XE**)
 - `storage.dump.dir` - data pump directory in Oracle XE
 - `initial.db.import` - set to **true** in case of initial import on new environment (default **false**)
 - `tablespace` - user's tablespace name on target environment (default **USERS**)
 - `tablespace.remap` - user's tablespace name on source environment (default **USERS**)
 - `dyn.admin.password` - hashed dyn/admin admin password
 - `<schema_type>.fix.bcc.password` - to update bcc admin password (**true** for pub schema)
 - `<schema_type>.fix.admin.password` - to update dyn/amin admin password
 - `bcc.admin.password` - hashed bcc admin password
 - `bcc.admin.password.salt` - hashed bcc admin password salt
 - `csc.service.password` - hashed csc service password (if CSC is installed)
 - `csc.service.password.salt` - hashed csc service password salt
 - `agent.fix.csc.password` - to update bcc admin password (**true** for agent schema)
 - `list.of.saved.tables` - list of saved tables during dump importing on target database for all schemas
 - `<schema>.list.of.saved.tables` - list of saved tables during dump importing on target database for defined schema

For each database schema in list `db.schemas_to_import` must be set schema name, password and dump file, e.g.

```
pub.db.user=<schema_name>
pub.db.password=<schema_password>
pub.dump.filename=<schema_name>.dmp

core.db.user=<schema_name>
core.db.password=<schema_password>
core.dump.filename=<schema_name>.dmp
```

If you want to add additional project tables for saving during dump importing, set parameters:

 - `project.list.of.saved.tables` - for all schemas in list db.schemas_to_import
 - `<schema_type>.project.list.of.saved.tables` - for <schema_type> schema (e.g. pub.project.list.of.saved.tables)

###### Steps in target importFromDumpRDS for each schema in `db.schemas_to_import`

 - create/recreate database link from storage XE to target RDS database (**createDBlink**)
 - copy dump file from storage XE to RDS database using DBMS_FILE_TRANSFER.PUT_FILE (overwriting previous if exists) (**copyDumpFromStorageRDS**)
 - truncate schema (in case tables for saving data are defined, schema will be truncated except these tables)  (**dropUserContent**)
 - run impdp (**importSchemaFromDumpRDS**)
 - delete dump file on target database (**deleteDumpFromRDS**)
 - uploading BCC deployment topology if initial.db.import is set to true (**uploadDeploymentTopology**)
 - update admin user password for dyn/admin (**fixAdminPasswords**)
 - update admin user password for bcc (**fixAdminPasswords**)
 - remove incompleted BCC projects in pub schema (**removeIncompletedProjects**)

It's essential to set schema names remap of source environment, e.g.

```
pub.user.remap=<source_bcc_schema>
core.user.remap=<source_core_schema>
```

If `initial.db.import` set to `true` set `deployment.topology.file` to environment deployment topology sql file


##### non-RDS database


```
ATG Schemas must be created in target database preliminarily
```


```
cd datacut
ant -lib <path_to_build.lib.dir_directory> importFromDump
```

###### Required grants for ATG schemas

```
grant READ,WRITE ON DIRECTORY data_pump_dir to <schema_name>;
grant IMP_FULL_DATABASE TO <schema_name>;
```

###### Parameters for importing dumps

 - `env` - target environment
 - `db.host` - database host
 - `db.port` - database port
 - `db.sid` - database sid
 - `dump.dir` - oracle directory to export dumps (default **DATA_PUMP_DIR**)
 - `db.configs` - list of ATG schemas on target environment
 - `oracle.ssh.user` - user to connect to database server via SSH
 - `db.schemas_to_import` - list of db schemas for importing from dumps
 - `initial.db.import` - set to **true** in case of initial import on new environment (default **false**)
 - `ORACLE_HOME` - oracle home directory on source environment
 - `storage.dump.directory` - directory to save dumps on storage server (default, **/opt/datacut/db_dumps**)
 - `tablespace` - user's tablespace name on target environment (default **USERS**)
 - `tablespace.remap` - user's tablespace name on source environment (default **USERS**)
 - `dyn.admin.password` - hashed dyn/admin admin password
 - `<schema_type>.fix.bcc.password` - to update bcc admin password (**true** for pub schema)
 - ``<schema_type>.fix.admin.password` - to update dyn/amin admin password (**true** for pub, core, agent, prv schemas)
 - `bcc.admin.password` - hashed bcc admin password
 - `bcc.admin.password.salt` - hashed bcc admin password salt
 - `csc.service.password` - hashed csc service password (if CSC is installed)
 - `csc.service.password.salt` - hashed csc service password salt
 - `agent.fix.csc.password` - to update bcc admin password (**true** for agent schema)
 - `list.of.saved.tables` - list of saved tables during dump importing on target database for all schemas
 - `<schema>.list.of.saved.tables` - list of saved tables during dump importing on target database for defined schema

For each database schema in list `db.schemas_to_import` must be set schema name, password and dump file, e.g.

```
pub.db.user=<schema_name>
pub.db.password=<schema_password>
pub.dump.filename=<schema_name>.dmp

core.db.user=<schema_name>
core.db.password=<schema_password>
core.dump.filename=<schema_name>.dmp
```

If you want to add additional project tables for saving during dump importing, set parameters:

 - `project.list.of.saved.tables` - for all schemas in list db.schemas_to_import
 - `<schema_type>.project.list.of.saved.tables` - for <schema_type> schema (e.g. pub.project.list.of.saved.tables)

###### Steps in target importFromDump for each schema in `db.schemas_to_import`

 - copy dump file from storage to database server using rsync (overwriting previous if exists) (**copyDumpFromStorage**)
 - verify dump files where copied to dump directory (**verifyDumpFile**)
 - generate ddl sql script from dump file (**generateSQLscript**)
 - truncate schema (in case tables for saving data are defined, schema will be truncated except these tables)  (**dropUserContent**)
 - execute generated sql script, disable constraints in schema (**runSQLScript**)
 - run impdp, enable constraints in schema (**importSchemaFromDump**)
 - delete dump file on oracle database server (**deleteDumpFromDbHost**)
 - uploading BCC deployment topology if initial.db.import is set to true (**uploadDeploymentTopology**)
 - update admin user password for dyn/admin (**fixAdminPasswords**)
 - update admin user password for bcc (**fixAdminPasswords**)
 - update service user password for csc (**fixAdminPasswords**)
 - remove incompleted BCC projects in pub schema (**removeIncompletedProjects**)

It's essential to set schema names remap of source environment, e.g.

```
pub.user.remap=<source_bcc_schema>
core.user.remap=<source_core_schema>
```

If `initial.db.import` set to `true` set `deployment.topology.file` to environment deployment topology sql file


## License

Apache2

## Authors

  - Anastacia Maletskaya  
    <anastacia_maletskaya@lean-delivery.com>