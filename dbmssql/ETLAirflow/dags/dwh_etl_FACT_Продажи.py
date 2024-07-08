import datetime as dt
from airflow import DAG , models
from airflow.operators.empty import EmptyOperator
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook
from airflow.providers.microsoft.mssql.operators.mssql import MsSqlOperator

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
        src = MsSqlHook(mssql_conn_id='mssql_dwh')
        src_conn = src.get_conn()
        src.set_autocommit(src_conn, True)
        cursor = src_conn.cursor()
        params = (v_session_id)
        cursor.execute("EXEC [staging].[sp_FACT_Продажи_transfer] @session_id = %d", params)
        logging.info("EXEC [staging].[sp_FACT_Продажи_transfer].")
        cursor.execute("EXEC [staging].[sp_FACT_Продажи_rekey] @session_id = %d", params)
        logging.info("EXEC [staging].[sp_FACT_Продажи_rekey].")
        cursor.execute("EXEC [staging].[sp_FACT_Продажи_publish] @session_id = %d", params)
        logging.info("EXEC [staging].[sp_FACT_Продажи_publish].")
        cursor.close()
        src_conn.close()
        session.commit()

    (
         exec_publish()
    )

