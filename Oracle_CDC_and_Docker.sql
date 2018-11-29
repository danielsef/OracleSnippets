docker run -d -p 8080:8080 -p 1521:1521 -e DBCA_TOTAL_MEMORY=2024 --name oracle12c_1 sath89/oracle-ee-12c
docker exec -ti oracle12c_1 /bin/bash


Run with sys (pw: oracle) user from sqlplus:

select log_mode from v$database;
shutdown immediate;
startup mount;
alter database archivelog;
alter database open;

SELECT supplemental_log_data_min, supplemental_log_data_pk, supplemental_log_data_all FROM v$database;

ALTER DATABASE ADD SUPPLEMENTAL LOG DATA (PRIMARY KEY) COLUMNS;
ALTER DATABASE ADD SUPPLEMENTAL LOG DATA (ALL) COLUMNS;
ALTER SYSTEM SWITCH LOGFILE;

CREATE USER streamsets IDENTIFIED BY streamsets;
GRANT create session, alter session, select any dictionary, logmining, execute_catalog_role TO streamsets;

--GRANT select on <db>.<table> TO streamsets;

EXECUTE DBMS_LOGMNR_D.BUILD(OPTIONS=> DBMS_LOGMNR_D.STORE_IN_REDO_LOGS);


--Oracle Database 12c Enterprise Edition Release 12.2.0.1.0 - 64bit Production

https://www.oracle.com/technetwork/database/features/jdbc/jdbc-ucp-122-3110062.html

----------------------------------------------------------------------


docker commit -m "12c with suppl. logging" 30b52d31d1dd sath89/oracle-ee-12c:1.1
docker save sath89/oracle-ee-12c:1.1 > sath89-oracle-ee-12c.tar
docker load < sath89-oracle-ee-12c.tar





