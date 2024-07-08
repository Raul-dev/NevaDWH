import datetime as dt
from airflow import DAG , models
from airflow.operators.empty import EmptyOperator
from airflow.hooks.postgres_hook import PostgresHook

import logging
from airflow.settings import Session

args = {
    'owner': 'airflow',
    'start_date': dt.datetime(2019, 11, 8, 23, 00, 00),
    'concurrency': 1,
}

with DAG(
    dag_id="dwh_etl_FACT_Продажи",
    default_args=args,
    schedule_interval=None,
    max_active_runs=1,
    start_date=dt.datetime(2020, 1, 1),
    tags=["ods"],

) as dag:

    @dag.task(task_id="exec_publish")
    def exec_publish():
        session = Session()
        #TODO get var
        v_session_id = models.Variable.get('session_id', default_var=-1)
        logging.info("Startint insert.")
        src = PostgresHook(postgres_conn_id='postgres_dwh')
        src_conn = src.get_conn()
        src.set_autocommit(src_conn, True)
        cursor = src_conn.cursor()
        params = (v_session_id)
        cursor.execute(f"""CALL staging."sp_FACT_Продажи_t"({v_session_id})""", params)
        logging.info("CALL staging.sp_FACT_Продажи_t %s", v_session_id)
        cursor.execute(f"""CALL staging."sp_FACT_Продажи_r"({v_session_id})""", params)
        logging.info("CALL staging.sp_FACT_Продажи_r")
        cursor.execute(f"""CALL staging."sp_FACT_Продажи_p"({v_session_id})""")
        logging.info("CALL staging.sp_FACT_Продажи_p")
        cursor.close()
        src_conn.close()
        session.commit()

    (
         exec_publish()
    )

