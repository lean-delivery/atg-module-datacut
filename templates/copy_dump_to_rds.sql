BEGIN
DBMS_FILE_TRANSFER.PUT_FILE(
source_directory_object       => '@STORAGE_DUMP_DIR@',
source_file_name              => '@DUMPFILE@',
destination_directory_object  => '@DUMPDIR@',
destination_file_name         => '@DUMPFILE@', 
destination_database          => '@DATABASE_LINK@' 
);
END;
/ 