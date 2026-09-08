import datetime as dt
from airflow import DAG , models
from airflow.providers.standard.operators.empty import EmptyOperator
from airflow.providers.standard.operators.trigger_dagrun import TriggerDagRunOperator

args = {
  'owner': 'airflow',
  'start_date': dt.datetime(2019, 11, 8, 23, 00, 00),
}

with DAG(
  dag_id="dwh_etl_Star_Launcher",
  default_args=args,
  schedule=None,
  max_active_runs=1,
  # Parallel DIM triggers (was 1 → serialized + default poke_interval=60s per star)
  max_active_tasks=16,
  start_date=dt.datetime(2020, 1, 1),
  tags=["ods"],

) as dag:
  empty_task = EmptyOperator(
    task_id='task_for_empty_list'
  )

  Run_DIM_Valyuty = TriggerDagRunOperator(
    task_id='Run_DIM_Valyuty',
    trigger_dag_id='dwh_etl_DIM_Valyuty',
    wait_for_completion=True,
    poke_interval=5,
  )
  Run_DIM_Klienty = TriggerDagRunOperator(
    task_id='Run_DIM_Klienty',
    trigger_dag_id='dwh_etl_DIM_Klienty',
    wait_for_completion=True,
    poke_interval=5,
  )
  Run_DIM_Tovary = TriggerDagRunOperator(
    task_id='Run_DIM_Tovary',
    trigger_dag_id='dwh_etl_DIM_Tovary',
    wait_for_completion=True,
    poke_interval=5,
  )
  Run_FACT_Prodazhi = TriggerDagRunOperator(
    task_id='Run_FACT_Prodazhi',
    trigger_dag_id='dwh_etl_FACT_Prodazhi',
    wait_for_completion=True,
    poke_interval=5,
  )

  # DIMs in parallel, then FACTs. Airflow 3: no list>>list — join via EmptyOperator.
  dim_runs = [Run_DIM_Valyuty, Run_DIM_Klienty, Run_DIM_Tovary, ]
  fact_runs = [Run_FACT_Prodazhi, ]
  if dim_runs and fact_runs:
    dims_done = EmptyOperator(task_id='dims_done')
    for _t in dim_runs:
      _t >> dims_done
    for _t in fact_runs:
      dims_done >> _t
  empty_task

