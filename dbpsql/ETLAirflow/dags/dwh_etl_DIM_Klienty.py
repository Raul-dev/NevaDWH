import datetime as dt
from airflow import DAG
from airflow.hooks.postgres_hook import PostgresHook
from airflow.sdk import Variable

import logging

args = {
  'owner': 'airflow',
  'start_date': dt.datetime(2019, 11, 8, 23, 00, 00),
}

with DAG(
  dag_id="dwh_etl_DIM_Klienty",
  default_args=args,
  schedule=None,
  max_active_runs=1,
  max_active_tasks=1,
  start_date=dt.datetime(2020, 1, 1),
  tags=["ods"],

) as dag:

  @dag.task(task_id="exec_publish")
  def exec_publish():
    v_session_id = Variable.get('session_id', default=-1)
    logging.info("Startint insert.")
    src = PostgresHook(postgres_conn_id='postgres_dwh')
    src_conn = src.get_conn()
    src.set_autocommit(src_conn, True)
    cursor = src_conn.cursor()
    params = (v_session_id)
    cursor.execute(f"""CALL staging."sp_DIM_Клиенты_t"({v_session_id})""", params)
    logging.info("CALL staging.sp_DIM_Клиенты_t %s", v_session_id)
    cursor.execute(f"""CALL staging."sp_DIM_Клиенты_r"({v_session_id})""", params)
    logging.info("CALL staging.sp_DIM_Клиенты_r")
    cursor.execute(f"""CALL staging."sp_DIM_Клиенты_p"({v_session_id})""")
    logging.info("CALL staging.sp_DIM_Клиенты_p")
    cursor.close()
    src_conn.close()

  (
    exec_publish()
  )

