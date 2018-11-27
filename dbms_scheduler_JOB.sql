BEGIN
 dbms_scheduler.create_job('RUN_EIM_POST_1197624',
                            job_type            => 'PLSQL_BLOCK',
                            job_action          => 'begin
                                                        m012_eim_load.run(p_session_id => <p_session_id>);
                                                    END;
                                                    ',
                            number_of_arguments => 0,
                            start_date          => sysdate,
                            repeat_interval     => NULL,
                            end_date            => NULL,
                            job_class           => 'DEFAULT_JOB_CLASS',
                            enabled             => FALSE,
                            auto_drop           => FALSE,
                            comments            => NULL);
END;
 
BEGIN
  DBMS_SCHEDULER.run_job(job_name        => 'RUN_EIM_POST_1197624',
                         use_current_session => FALSE);
END;
