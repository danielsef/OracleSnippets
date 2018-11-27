

--1.)SQL PLAN - Ha epp fut valami, akkor ezt futtassuk:
SELECT s.sql_id,
       s.SID,
       sq.SQL_TEXT,
       sq.CHILD_NUMBER,
       XPLAN.display_cursor(p_sql_id          => s.SQL_ID,
                                 p_format          => 'ALL',
                                 p_cursor_child_no => sq.CHILD_NUMBER) AS SQL_PLAN
  FROM v$session s, gv$sql sq
 WHERE sq.sql_id = s.sql_id
   AND s.SID = 128--PARAM
   AND s.SERIAL#=24995--PARAM
   AND s.STATUS = 'ACTIVE';
 
 
 
--2.)SQL + PCK+Line - Ha epp fut valami, akkor ezt futtassuk:
SELECT o.OWNER,--
       o.OBJECT_NAME,--
       s.PROGRAM_ID,
       s.PROGRAM_LINE#,
       s.SQL_ID,
       s.CHILD_NUMBER,
       s.SQL_TEXT,--
       s.SQL_FULLTEXT,--
       trunc(s.ELAPSED_TIME/1000000) ELAPSED_TIME_SEC
  FROM v$sql s, dba_objects o
 WHERE s.SQL_ID IN (SELECT s.sql_id
                      FROM v$session s, gv$sql sq
                     WHERE sq.sql_id = s.sql_id
                       AND s.SID = 128--PARAM
                       AND s.STATUS = 'ACTIVE')
   AND o.OBJECT_ID = s.PROGRAM_ID;
 
--3.) 
SELECT * FROM V$SQL_BIND_CAPTURE b WHERE b.sql_id = p_sql_id;
 
 
----------------- Hierarchical Profiler elemzes - ha lefutott a Job ----------------
 
 
 
--1          
SELECT runid, run_timestamp, trunc(total_elapsed_time/1000000)  total_elapsed_time_sec, run_comment
  FROM dbmshp_runs r
  where r.run_comment like '%1000%'--PARAM
 ORDER BY runid DESC;

 
--Full tree       
SELECT level,
       -- a.owner,
       RPAD(' ', (level - 1) * 2, ' ') || a.name AS name,
       a.parentsymid,
       a.symbolid,
       a.subtree_elapsed_time_sec,
       a.function_elapsed_time_sec,
       a.calls,
       namespace
  FROM (SELECT fi.symbolid,
               pci.parentsymid,
               -- fi.owner,
               RTRIM(fi.owner || '.' || fi.module || '.' ||
                     NULLIF(fi.FUNCTION, fi.module),
                     '.') AS name,
               trunc(NVL(pci.subtree_elapsed_time, fi.subtree_elapsed_time)/1000000) AS subtree_elapsed_time_sec,
               trunc(NVL(pci.function_elapsed_time, fi.function_elapsed_time)/1000000) AS function_elapsed_time_sec,
               NVL(pci.calls, fi.calls) AS calls,
               namespace
          FROM dbmshp_function_info fi
          LEFT JOIN dbmshp_parent_child_info pci
            ON fi.runid = pci.runid
           AND fi.symbolid = pci.childsymid
         WHERE fi.runid = 29) a
CONNECT BY a.parentsymid = PRIOR a.symbolid
 START WITH a.parentsymid IS NULL;
 
--Sub tree
SELECT level lev,
       -- a.owner,
       RPAD(' ', (level - 1) * 2, ' ') || a.name AS name,
       a.parentsymid,
       a.symbolid,
       a.subtree_elapsed_time,
       trunc(a.subtree_elapsed_time / 1000000) AS subtree_elapsed_time_sec,
       a.function_elapsed_time,
       a.calls,
       namespace
  FROM (SELECT fi.symbolid,
               pci.parentsymid,
               -- fi.owner,
               RTRIM(fi.owner || '.' || fi.module || '.' ||
                     NULLIF(fi.FUNCTION, fi.module),
                     '.') AS name,
               NVL(pci.subtree_elapsed_time, fi.subtree_elapsed_time) AS subtree_elapsed_time,
               NVL(pci.function_elapsed_time, fi.function_elapsed_time) AS function_elapsed_time,
               NVL(pci.calls, fi.calls) AS calls,
               namespace
          FROM dbmshp_function_info fi
          LEFT JOIN dbmshp_parent_child_info pci
            ON fi.runid = pci.runid
           AND fi.symbolid = pci.childsymid
         WHERE fi.runid = 16) a
CONNECT BY a.parentsymid = PRIOR a.symbolid
 START WITH a.symbolid = 48;
