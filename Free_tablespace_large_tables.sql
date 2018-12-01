--Largest tables in tablespace
SELECT top150.owner, top150.TABLE_NAME, meg, a.num_rows
  FROM dba_tables a,
       (SELECT *
          FROM (SELECT owner, TABLE_NAME, TRUNC(SUM(bytes) / 1024 / 1024) Meg
                  FROM (SELECT segment_name TABLE_NAME, owner, bytes
                          FROM dba_segments
                         WHERE segment_type LIKE 'TABLE%'
                           AND owner ='PARAM'                         
                        UNION ALL
                        SELECT i.TABLE_NAME, i.owner, s.bytes
                          FROM dba_indexes i, dba_segments s
                         WHERE s.segment_name = i.index_name
                           AND s.owner = i.owner
                           AND i.owner ='PARAM'                           
                           AND s.segment_type LIKE 'INDEX%'
                        UNION ALL
                        SELECT l.TABLE_NAME, l.owner, s.bytes
                          FROM dba_lobs l, dba_segments s
                         WHERE s.segment_name = l.segment_name
                           AND s.owner = l.owner
                           AND l.owner ='TSMART'
                           AND s.segment_type = 'LOBSEGMENT'
                        UNION ALL
                        SELECT l.TABLE_NAME, l.owner, s.bytes
                          FROM dba_lobs l, dba_segments s
                         WHERE s.segment_name = l.index_name
                           AND l.owner ='PARAM'
                           AND s.owner = l.owner
                           AND s.segment_type = 'LOBINDEX')
                 GROUP BY TABLE_NAME, owner
                HAVING SUM(bytes) / 1024 / 1024 > 10 /* Ignore small tables */
                 ORDER BY SUM(bytes) DESC)
         WHERE rownum < 151) top150
 WHERE top150.owner = a.owner
   AND top150.TABLE_NAME = a.TABLE_NAME
   AND a.OWNER='PARAM'
 ORDER BY meg DESC, num_rows DESC;
 
 
--táblatér elemzés:
SELECT a.tablespace_name,
       round(SUM(a.bytes) / (1024 * 1024 * 1024)) CURRENT_GB,
       round(SUM(decode(b.maxextend,
                        NULL,
                        A.BYTES / (1024 * 1024 * 1024),
                        b.maxextend * 8192 / (1024 * 1024 * 1024)))) MAX_GB,
       (SUM(a.bytes) / (1024 * 1024 * 1024) -
       round(c.Free / 1024 / 1024 / 1024)) USED_GB,
       round((SUM(decode(b.maxextend,
                         NULL,
                         A.BYTES / (1024 * 1024 * 1024),
                         b.maxextend * 8192 / (1024 * 1024 * 1024))) -
             (SUM(a.bytes) / (1024 * 1024 * 1024) -
             round(c.Free / 1024 / 1024 / 1024))),
             2) FREE_GB,
       round(100 * (SUM(a.bytes) / (1024 * 1024 * 1024) -
             round(c.Free / 1024 / 1024 / 1024)) /
             (SUM(decode(b.maxextend,
                         NULL,
                         A.BYTES / (1024 * 1024 * 1024),
                         b.maxextend * 8192 / (1024 * 1024 * 1024))))) USED_PCT
  FROM dba_data_files a,
       sys.filext$ b,
       (SELECT d.tablespace_name, SUM(nvl(c.bytes, 0)) Free
          FROM dba_tablespaces d, DBA_FREE_SPACE c
         WHERE d.tablespace_name = c.tablespace_name(+)
         GROUP BY d.tablespace_name) c
 WHERE a.file_id = b.file#(+)
   AND a.tablespace_name = c.tablespace_name
 GROUP BY a.tablespace_name, c.Free / 1024
 ORDER BY tablespace_name;
 
 
SELECT
    s.owner,
   -- s.segment_name,
   -- s.segment_type,
    TRUNC(SUM(s.bytes)/1024/1024) "MB" 
FROM
    dba_segments  s
WHERE  s.owner='PARAM'
 AND (s.segment_type LIKE 'INDEX%' 
     OR    s.segment_type  = 'TABLE PARTITION' 
     OR s.segment_type = 'LOBSEGMENT'
     OR s.segment_type = 'LOBINDEX')
 AND s.tablespace_name='PARAM'
--AND s.segment_name IN ('M001_FLOW_STAT_DTL','M001_GROUP_LI','M001_FLOW_STAT_CORE')  --itt kell felsorolni a táblák nevét
AND s.partition_name IN (SELECT 'P_'||session_id
                          FROM m001_session
                          WHERE STATUS !='sent_to_siebel'
                          AND last_modified_dt<to_date('20180101', 'YYYYMMDD') --melyik session_id-kat akarjuk törölni
                        )
GROUP BY  s.owner
   -- s.segment_name,
   -- s.segment_type
;
