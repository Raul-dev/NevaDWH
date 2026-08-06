import datetime as dt
import logging

from airflow import DAG
from airflow.providers.microsoft.mssql.hooks.mssql import MsSqlHook
from airflow.providers.standard.operators.python import ShortCircuitOperator
from airflow.providers.standard.operators.trigger_dagrun import TriggerDagRunOperator
from airflow.sdk import Variable

def IsNotEmpty():
    v_dwh_session_count = Variable.get("dwh_session_count", default=-1)
    return int(v_dwh_session_count) > 0

args = {
    "owner": "airflow",
    "start_date": dt.datetime(2019, 11, 8, 23, 00, 00),
    "retries": 0,
}

with DAG(
    dag_id="dwh_etl_start",
    default_args=args,
    max_active_tasks=1,
    schedule=None,
    catchup=False,
    start_date=dt.datetime(2020, 1, 1),
    tags=["ods"],
) as dag:

    @dag.task(task_id="start_dwh_session")
    def start_dwh_session():
        # ODS: [etl].[dwh_AssignSessionID]
        src = MsSqlHook(mssql_conn_id="mssql_ods")
        src_conn = src.get_conn()
        src.set_autocommit(src_conn, True)
        cursor = src_conn.cursor()
        cursor.execute("EXEC [etl].[dwh_AssignSessionID];")

        session_row_id = 0
        v_count = 0
        for row in cursor:
            logging.info(f"dwh session id = {row[0]} Count ={row[1]}")
            session_row_id = row[0]
            v_count = row[1]

        if v_count > 0:
            Variable.set("dwh_session_id", str(session_row_id))
            Variable.set("dwh_session_count", str(v_count))
            logging.info("dwh id variable %d" % (session_row_id))
        else:
            Variable.set("dwh_session_id", "0")
            Variable.set("dwh_session_count", "0")
            logging.info("dwh id variable %d" % (session_row_id))

        cursor.close()
        src_conn.close()

        # DWH: [mq].[sp_SaveSessionState]
        logging.info("Start session v_count= %d" % (v_count))
        if v_count > 0:
            src = MsSqlHook(mssql_conn_id="mssql_dwh")
            src_conn = src.get_conn()
            src.set_autocommit(src_conn, True)
            cursor = src_conn.cursor()
            v_dwh_session_id = Variable.get("dwh_session_id", default=-1)
            params = (v_dwh_session_id, v_count)
            cursor.execute(
                "EXEC [mq].[sp_SaveSessionState] @SessionId=NULL, @DwhSessionId=%d, @RowsCount=%d, @SessionStateId=1;",
                params,
            )
            dwh_session_id = 0
            for row in cursor:
                logging.info(f"session id = {row[0]}")
                dwh_session_id = row[0]

            Variable.set("session_id", str(dwh_session_id))
            logging.info("id variable %s" % (dwh_session_id))
            cursor.close()
            src_conn.close()
        else:
            Variable.set("session_id", "0")

    IsNotEmpty = ShortCircuitOperator(
        task_id="IsNotEmpty",
        python_callable=IsNotEmpty,
    )
    RunListOfStars = TriggerDagRunOperator(
        task_id="Run_dwh_etl_Star_Launcher",
        trigger_dag_id="dwh_etl_Star_Launcher",
        wait_for_completion=True,
    )

    @dag.task(task_id="finish_dwh_session")
    def finish_dwh_session():
        # DWH: close mq session
        src = MsSqlHook(mssql_conn_id="mssql_dwh")
        src_conn = src.get_conn()
        src.set_autocommit(src_conn, True)
        cursor = src_conn.cursor()
        v_session_id = Variable.get("session_id", default=-1)
        cursor.execute(
            "EXEC [mq].[sp_SaveSessionState] @SessionId=%d, @SessionStateId=2;",
            (v_session_id,),
        )
        cursor.close()
        src_conn.close()

        # ODS: close etl dwh session
        src = MsSqlHook(mssql_conn_id="mssql_ods")
        src_conn = src.get_conn()
        src.set_autocommit(src_conn, True)
        cursor = src_conn.cursor()
        v_dwh_session_id = Variable.get("dwh_session_id", default=-1)
        cursor.execute(
            "EXEC [etl].[dwh_SaveSessionState] @DwhSessionId=%d, @DwhSessionStateId=4;",
            (v_dwh_session_id,),
        )
        cursor.close()
        src_conn.close()

    start_dwh_session() >> IsNotEmpty >> RunListOfStars >> finish_dwh_session()
