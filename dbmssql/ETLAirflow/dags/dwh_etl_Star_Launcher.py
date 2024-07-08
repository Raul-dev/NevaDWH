import datetime as dt
from airflow import DAG , models
from airflow.operators.empty import EmptyOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator

args = {
    'owner': 'airflow',
    'start_date': dt.datetime(2019, 11, 8, 23, 00, 00),
    'concurrency': 1,
}

with DAG(
    dag_id="dwh_etl_Star_Launcher",
    default_args=args,
    schedule_interval=None,
    max_active_runs=1,
    start_date=dt.datetime(2020, 1, 1),
    tags=["ods"],

) as dag:
    empty_task = EmptyOperator(
        task_id='task_for_empty_list'
    )

    Run_DIM_Валюты = TriggerDagRunOperator(
        task_id='Run_DIM_Валюты',
        trigger_dag_id='dwh_etl_DIM_Валюты',
        wait_for_completion=True
    )
    Run_DIM_Клиенты = TriggerDagRunOperator(
        task_id='Run_DIM_Клиенты',
        trigger_dag_id='dwh_etl_DIM_Клиенты',
        wait_for_completion=True
    )
    Run_DIM_Товары = TriggerDagRunOperator(
        task_id='Run_DIM_Товары',
        trigger_dag_id='dwh_etl_DIM_Товары',
        wait_for_completion=True
    )
    Run_FACT_Продажи = TriggerDagRunOperator(
        task_id='Run_FACT_Продажи',
        trigger_dag_id='dwh_etl_FACT_Продажи',
        wait_for_completion=True
    )

    (
       [Run_DIM_Валюты,Run_DIM_Клиенты,Run_DIM_Товары,Run_FACT_Продажи,empty_task]
    )

