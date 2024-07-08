import datetime as dt
from airflow import DAG , models

from airflow.hooks.postgres_hook import PostgresHook
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from airflow.operators.python import ShortCircuitOperator
import logging
#from airflow import models
from airflow.settings import Session

v_dwh_session_id = 0
id=0
v_count=0
def IsNotEmpty():
    v_dwh_session_count  = models.Variable.get('dwh_session_count', default_var=-1)
    if int(v_dwh_session_count) > 0:
        return True
    return False 
args = {
    'owner': 'airflow',
    'start_date': dt.datetime(2019, 11, 8, 23, 00, 00),
    'retries': 0,
}

with DAG(
    dag_id="dwh_etl_start",
    default_args=args,
    concurrency= 1,
#    retries=0,
#    schedule_interval=dt.timedelta(minutes=1),
#    dagrun_timeout=dt.timedelta(minutes=1),
#    schedule_interval=dt.timedelta(seconds=10),
#    dagrun_timeout=dt.timedelta(seconds=10),
    schedule_interval=None,
    catchup=False,
    max_active_runs=1,
    start_date= dt.datetime(2020, 1, 1),
    tags=["ods"],

) as dag:
        
    @dag.task(task_id="start_dwh_session")
    def start_dwh_session():
        logging.info("Start main task")
        session = Session()
        src = PostgresHook(postgres_conn_id='postgres_ods',)
        src_conn = src.get_conn()
        src.set_autocommit(src_conn, True)
        cursor = src_conn.cursor()
        #params = (v_dwh_session_id, v_count, v_session_date) 
        cursor.execute("""CALL public."dwh_AssignSessionID"(null::bigint, null::bigint, null::timestamp)""")
        v_dwh_session_id  = models.Variable.get('dwh_session_id', default_var=-1)
        new_var = models.Variable()
        new_var.type = int
        new_var.key = "dwh_session_id"
        logging.info(f"v_dwh_session id = {v_dwh_session_id}")
        if int(v_dwh_session_id) == -1:
            new_var.set_val(str(0))
            session.add(new_var)
            session.commit()
            logging.info(f"Added variable dwh_session_id")
        v_dwh_session_count  = models.Variable.get('dwh_session_count', default_var=-1)
        new_var2 = models.Variable()
        new_var2.type = int
        new_var2.key = "dwh_session_count"
        logging.info(f"v_dwh_session_count = {v_dwh_session_count}")

        if int(v_dwh_session_count) == -1:
            new_var2.set_val(str(0))
            session.add(new_var2)
            session.commit()
            logging.info(f"Added variable v_dwh_session_count")
        
        for row in cursor:
            logging.info(f"dwh session id = {row[0]} Count ={row[1]}, date ={row[2]}")
            id = row[0]
            v_count = row[1]
            v_session_date  = row[2]
        
        if v_count > 0:
            v_dwh_session_id = str(id) 
            v_dwh_session_count= str(v_count) 
            logging.info("dwh id variable %d" % (id))
            new_var.update(key="dwh_session_id", value=v_dwh_session_id, session=session)
            new_var2.update(key="dwh_session_count", value=v_dwh_session_count, session=session)
        else:
            v_dwh_session_id = str(0) 
            v_dwh_session_count= str(0) 
            logging.info("Empty dwh id variable %d" % (id))
            new_var.update(key="dwh_session_id", value=v_dwh_session_id, session=session)
            new_var2.update(key="dwh_session_count", value=v_dwh_session_count, session=session)

        cursor.close()
        src_conn.close()
        session.commit()
        session = Session()
        logging.info("Start session v_count= %d" % (v_count))
        src = PostgresHook(postgres_conn_id='postgres_dwh')
        v_session_id  = models.Variable.get('session_id', default_var=-1)        
        new_var = models.Variable()
        new_var.type = int
        new_var.key = "session_id"
        logging.info(f"v_session id = {v_session_id}")        
        if v_session_id == -1:
            new_var.set_val(str(0))
            session.add(new_var)
            session.commit()
            logging.info(f"Added variable session_id")

        if v_count > 0:
            src_conn = src.get_conn()
            src.set_autocommit(src_conn, True)
            cursor = src_conn.cursor()
            v_dwh_session_id  = models.Variable.get('dwh_session_id', default_var=-1) 
            #params = (v_dwh_session_id, v_count, v_session_date) 
            logging.info("Type %s Date %s",type(v_session_date),v_session_date)
            params = (v_session_date) 
            #call public."sp_SaveSessionState"(NULL::bigint, 7::bigint, 2123::bigint, 1::smallint, null::smallint, '2023-08-27 21:06:57.878293'::timestamp without time zone, null::varchar(4000))
            cursor.execute(f"""CALL public."sp_SaveSessionState"(NULL::bigint, {v_dwh_session_id}::bigint, {v_count}::bigint, 1::smallint, null::smallint, '{v_session_date}'::timestamp without time zone, null::varchar(4000))""")
       
            id=0
            for row in cursor:
                logging.info(f"session id = {row[0]}")
                id = row[0]
                
            v_session_id = str(id) 
            logging.info("id variable %s" % (v_session_id))
            new_var.update(key="session_id", value=v_session_id, session=session)
        
            cursor.close()
            src_conn.close()
        else:
            v_session_id = str(0) 
            new_var.update(key="session_id", value=v_session_id, session=session)
        session.commit()
        logging.info("Finish main task")

    IsNotEmpty = ShortCircuitOperator(
        task_id='IsNotEmpty',
        python_callable=IsNotEmpty,
    )
    RunListOfStars = TriggerDagRunOperator(
        task_id='Run_dwh_etl_Star_Launcher',
        trigger_dag_id='dwh_etl_Star_Launcher',
        wait_for_completion=True
    )

    @dag.task(task_id="finish_dwh_session")
    def finish_dwh_session():
        src = PostgresHook(postgres_conn_id='postgres_dwh')
        src_conn = src.get_conn()
        src.set_autocommit(src_conn, True)
        cursor = src_conn.cursor()
        v_session_id  = models.Variable.get('session_id', default_var=-1)      
        #params = (v_session_id) 
        #cursor.execute("""CALL "sp_SaveSessionState" @session_id=%d, @session_state_id=2;""",params)
        cursor.execute(f"""CALL public."sp_SaveSessionState"({v_session_id}::bigint, NULL::bigint, NULL::bigint, 1::smallint, 2::smallint, NULL::timestamp without time zone, null::varchar(4000))""")
        cursor.close()
        src_conn.close()
        src = PostgresHook(postgres_conn_id='postgres_ods')
        src_conn = src.get_conn()
        src.set_autocommit(src_conn, True)
        cursor = src_conn.cursor()
        v_dwh_session_id  = models.Variable.get('dwh_session_id', default_var=-1)      
        params = (v_dwh_session_id) 
        cursor.execute("""CALL public."dwh_SaveSessionState"(%s::bigint, null::smallint, 4::smallint);""",params)
        cursor.close()
        src_conn.close()


    (
        start_dwh_session()>>IsNotEmpty>>RunListOfStars>>finish_dwh_session()
    )