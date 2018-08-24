BEGIN
DBMS_FILE_TRANSFER.GET_FILE(
source_directory_object       => '@DUMPDIR@',
source_file_name              => '@DUMPFILE@',
source_database               => '@DATABASE_LINK@',
destination_directory_object  => '@STORAGE_DUMP_DIR@',
destination_file_name         => '@DUMPFILE@' 
);
END;
/ 