select proc_syn.referenced_owner,
      proc_syn.referenced_name,
      proc_syn.referenced_type,
      tables.table_name
 from dba_dependencies proc_syn, dba_tables tables
where proc_syn.name like 'XY%'
  AND REFERENCED_TYPE in ('SYNONYM', 'TABLE', 'VIEW')
  AND proc_syn.referenced_name = tables.table_name(+)
--AND syn_tab.owner = 'PUBLIC'
--and proc_syn.referenced_owner ='PARAM'
order by proc_syn.referenced_owner,
         proc_syn.referenced_type,
         tables.table_name;
