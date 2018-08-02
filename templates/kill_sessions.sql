BEGIN
  FOR r IN (select sid,serial# from v$session where username = '@DB_USER@')
  LOOP
    EXECUTE IMMEDIATE 'alter system kill session ''' || r.sid 
      || ',' || r.serial# || '''';
  END LOOP;
END;
