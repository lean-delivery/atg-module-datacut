-- This this a template for environment deployment topology. For each environment create separate sql and set in deployment.topology.file property in each <env_name>.properties


-- Disable constraints and truncate tables if data exists

-- ALTER TABLE EPUB_TR_AGENTS DISABLE CONSTRAINT PT_TR_PR_ID_FK;
-- ALTER TABLE EPUB_TR_AGENTS DISABLE CONSTRAINT PT_AG_AG_ID_FK;
-- ALTER TABLE EPUB_TARGET DISABLE CONSTRAINT TARGETS_PK CASCADE;
-- ALTER TABLE EPUB_AGENT DISABLE CONSTRAINT TARGET_AGENT_PK CASCADE;
-- TRUNCATE TABLE EPUB_TR_AGENTS;
-- TRUNCATE TABLE EPUB_TR_DEST;
-- TRUNCATE TABLE EPUB_TOPOLOGY;
-- TRUNCATE TABLE EPUB_TL_TARGETS;
-- TRUNCATE TABLE EPUB_TARGET;
-- TRUNCATE TABLE EPUB_AGENT;
-- TRUNCATE TABLE EPUB_PRINC_ASSET;
-- TRUNCATE TABLE EPUB_INCLUD_ASSET;
-- TRUNCATE TABLE EPUB_EXCLUD_ASSET;
-- TRUNCATE TABLE EPUB_DEST_MAP;
-- TRUNCATE TABLE EPUB_AGENT_TRNPRT;

-- Mapping between CA agents and Targets
-- Add line for each mapping agent - deployment target

-- INSERT INTO EPUB_TR_AGENTS (TARGET_ID,AGENT_ID) VALUES ('target_id','agent_id');

-- Repository mapping
-- Add line for each mapping deployment target - source repository - target repository (production/staging)

--  INSERT INTO EPUB_TR_DEST (TARGET_ID,TARGET_SOURCE,TARGET_DESTINATION) VALUES ('target_id','source_repo','target_repo');

-- Deployment Topology

-- INSERT INTO EPUB_TOPOLOGY (TOPOLOGY_ID,VERSION,PRIMARY_TL) VALUES ('topology_id',version,primary_tl);

-- Mapping between target and topology
-- Add line for each mapping deployment topology - deployment target

-- INSERT INTO EPUB_TL_TARGETS (TOPOLOGY_ID,TARGET_ID,SEQUENCE_NUM) VALUES ('topology_id','target_id',sequence_num);

-- CA targets
-- Add line for each deployment target

--  INSERT INTO EPUB_TARGET (TARGET_ID,SNAPSHOT_NAME,VERSION,CREATION_TIME,MAIN_TARGET_ID,DISPLAY_NAME,DESCRIPTION,HALTED,FLAG_AGENTS,TARGET_TYPE) VALUES ('target_id',snapshot_name,version, trunc(sysdate),'main_target_id','display_name',description,halted,flag_agents,target_type);

-- CA agents
-- Add line for each deployment agent

-- INSERT INTO EPUB_AGENT (AGENT_ID,VERSION,CREATION_TIME,DISPLAY_NAME,DESCRIPTION,MAIN_AGENT_ID,TRANSPORT) VALUES ('agent_id',version,trunc(sysdate),'display_name',description,'main_agent_id','transport');

-- Add line for each deployment agent

--  INSERT INTO EPUB_PRINC_ASSET (AGENT_ID,PRINCIPAL_ASSETS) VALUES ('agent_id','REPOSITORY');


-- Datastores mapping to agents
-- Add line for each deployment agent

-- INSERT INTO EPUB_INCLUD_ASSET (AGENT_ID,INCLUDE_ASSETS) VALUES ('agent_id','include_assets');


-- Agent transport url
-- Add line for each deployment agent

-- INSERT INTO EPUB_AGENT_TRNPRT (TRANSPORT_ID,VERSION,TRANSPORT_TYPE,JNDI_NAME,RMI_URI) VALUES ('transport_id',version,transport_typ,jndi_name,'rmi_uri');

-- Enable constraints

-- ALTER TABLE EPUB_TARGET ENABLE CONSTRAINT TARGETS_PK;
-- ALTER TABLE EPUB_AGENT ENABLE CONSTRAINT TARGET_AGENT_PK;
-- ALTER TABLE EPUB_TR_AGENTS ENABLE CONSTRAINT PT_TR_PR_ID_FK;
-- ALTER TABLE EPUB_TR_AGENTS ENABLE CONSTRAINT PT_AG_AG_ID_FK;

-- COMMIT;
