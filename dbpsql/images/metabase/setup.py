#!/usr/bin/env python3
"""Metabase OSS bootstrap: admin, DWH, RU locale, 3 reports + dashboard."""
from __future__ import annotations

import json
import os
import sys
import time
import urllib.error
import urllib.request


def env(name: str, default: str = "") -> str:
  return os.environ.get(name, default).strip()


def http_json(
  method: str,
  url: str,
  payload: object | None = None,
  timeout: int = 60,
  session: str | None = None,
):
  data = None
  headers = {"Accept": "application/json"}
  if session:
    headers["X-Metabase-Session"] = session
  if payload is not None:
    data = json.dumps(payload).encode("utf-8")
    headers["Content-Type"] = "application/json"
  req = urllib.request.Request(url, data=data, headers=headers, method=method)
  try:
    with urllib.request.urlopen(req, timeout=timeout) as resp:
      body = resp.read().decode("utf-8")
      return resp.status, json.loads(body) if body else None
  except urllib.error.HTTPError as exc:
    body = exc.read().decode("utf-8", errors="replace")
    try:
      parsed = json.loads(body) if body else None
    except json.JSONDecodeError:
      parsed = body
    return exc.code, parsed
  except urllib.error.URLError as exc:
    return 0, str(exc)


def wait_ready(base: str, attempts: int = 90, delay: float = 2.0) -> None:
  health = f"{base}/api/health"
  for i in range(1, attempts + 1):
    status, _ = http_json("GET", health, timeout=5)
    if status == 200:
      print(f"metabase ready ({health})", flush=True)
      return
    print(f"waiting metabase [{i}/{attempts}] status={status}", flush=True)
    time.sleep(delay)
  raise SystemExit(f"timeout waiting for {health}")


def build_database_payload() -> dict | None:
  engine = env("METABASE_DWH_ENGINE")
  if not engine:
    return None
  host = env("METABASE_DWH_HOST")
  port = env("METABASE_DWH_PORT")
  db = env("METABASE_DWH_DB")
  user = env("METABASE_DWH_USER")
  password = env("METABASE_DWH_PASSWORD")
  name = env("METABASE_DWH_NAME", "DWH")
  if not all([host, port, db, user, password]):
    print("METABASE_DWH_* incomplete — skip database", flush=True)
    return None

  if engine == "postgres":
    details = {
      "host": host,
      "port": int(port),
      "dbname": db,
      "user": user,
      "password": password,
      "ssl": False,
    }
  elif engine in ("sqlserver", "mssql"):
    details = {
      "host": host,
      "port": int(port),
      "db": db,
      "user": user,
      "password": password,
      "ssl": False,
      "instance-name": None,
    }
    engine = "sqlserver"
  else:
    print(f"unknown METABASE_DWH_ENGINE={engine}", flush=True)
    return None

  return {
    "engine": engine,
    "name": name,
    "details": details,
    "auto_run_queries": True,
    "is_full_sync": True,
    "schedules": {},
  }


def do_initial_setup(base: str) -> bool:
  status, props = http_json("GET", f"{base}/api/session/properties")
  if status != 200 or not isinstance(props, dict):
    raise SystemExit(f"session properties failed: {status} {props}")

  if props.get("has-user-setup"):
    print("Metabase already set up", flush=True)
    return False

  token = props.get("setup-token")
  if not token:
    raise SystemExit("no setup-token")

  email = env("METABASE_ADMIN_EMAIL", "admin@neva.loc")
  password = env("METABASE_ADMIN_PASSWORD", "admin")
  payload: dict = {
    "token": token,
    "user": {
      "email": email,
      "password": password,
      "first_name": env("METABASE_ADMIN_FIRST_NAME", "Admin"),
      "last_name": env("METABASE_ADMIN_LAST_NAME", "NevaDWH"),
    },
    "prefs": {
      "site_name": env("METABASE_SITE_NAME", "NevaDWH"),
      "site_locale": "ru",
      "allow_tracking": False,
    },
  }
  database = build_database_payload()
  if database is not None:
    payload["database"] = database

  status, result = http_json("POST", f"{base}/api/setup", payload, timeout=180)
  if status in (200, 201):
    print(f"setup OK: {email} / {password}", flush=True)
    return True
  text = json.dumps(result) if not isinstance(result, str) else str(result)
  if "already" in text.lower() or status == 403:
    print(f"setup already done ({status})", flush=True)
    return False
  raise SystemExit(f"setup failed ({status}): {result}")


def login(base: str) -> str:
  email = env("METABASE_ADMIN_EMAIL", "admin@neva.loc")
  password = env("METABASE_ADMIN_PASSWORD", "admin")
  for attempt in range(1, 16):
    status, result = http_json(
      "POST",
      f"{base}/api/session",
      {"username": email, "password": password},
    )
    if status == 200 and isinstance(result, dict) and result.get("id"):
      print("login OK", flush=True)
      return str(result["id"])
    print(f"login retry [{attempt}/15]: {status} {result}", flush=True)
    time.sleep(2)
  raise SystemExit("login failed")


def ensure_locale(base: str, session: str) -> None:
  # Site-wide Russian UI
  for key, value in (
    ("site-locale", "ru"),
    ("report-timezone", "Europe/Moscow"),
  ):
    status, result = http_json(
      "PUT",
      f"{base}/api/setting/{key}",
      value,
      session=session,
    )
    print(f"setting {key}={value!r} -> {status}", flush=True)
    if status not in (200, 204) and status != 0:
      print(f"  warn: {result}", flush=True)

  status, result = http_json(
    "PUT",
    f"{base}/api/user/current",
    {"locale": "ru"},
    session=session,
  )
  print(f"user locale ru -> {status}", flush=True)


def ensure_database(base: str, session: str) -> int:
  name = env("METABASE_DWH_NAME", "DWH")
  status, result = http_json("GET", f"{base}/api/database", session=session)
  if status != 200:
    raise SystemExit(f"list databases failed: {status} {result}")

  databases = result if isinstance(result, list) else (result or {}).get("data") or []
  for db in databases:
    if isinstance(db, dict) and db.get("name") == name and not db.get("is_sample"):
      db_id = int(db["id"])
      print(f"database {name!r} id={db_id}", flush=True)
      # trigger sync (best-effort)
      http_json("POST", f"{base}/api/database/{db_id}/sync_schema", {}, session=session)
      return db_id

  payload = build_database_payload()
  if payload is None:
    raise SystemExit("DWH database missing and METABASE_DWH_* not set")

  status, result = http_json("POST", f"{base}/api/database", payload, session=session)
  if status not in (200, 201) or not isinstance(result, dict):
    raise SystemExit(f"create database failed: {status} {result}")
  db_id = int(result["id"])
  print(f"created database {name!r} id={db_id}", flush=True)
  http_json("POST", f"{base}/api/database/{db_id}/sync_schema", {}, session=session)
  return db_id


def ensure_collection(base: str, session: str) -> int:
  title = env("METABASE_COLLECTION_NAME", "Отчёты DWH")
  status, result = http_json("GET", f"{base}/api/collection", session=session)
  if status == 200 and isinstance(result, list):
    for col in result:
      if col.get("name") == title:
        print(f"collection exists id={col['id']}", flush=True)
        return int(col["id"])

  status, result = http_json(
    "POST",
    f"{base}/api/collection",
    {"name": title, "color": "#509EE3", "description": "Продажи, товары, продукты"},
    session=session,
  )
  if status not in (200, 201) or not isinstance(result, dict):
    raise SystemExit(f"create collection failed: {status} {result}")
  print(f"created collection id={result['id']}", flush=True)
  return int(result["id"])


def find_card(base: str, session: str, name: str) -> int | None:
  status, result = http_json("GET", f"{base}/api/card", session=session)
  if status != 200:
    return None
  cards = result if isinstance(result, list) else []
  for card in cards:
    if card.get("name") == name:
      return int(card["id"])
  return None


def create_card(
  base: str,
  session: str,
  *,
  name: str,
  description: str,
  database_id: int,
  sql: str,
  display: str,
  collection_id: int,
  visualization_settings: dict | None = None,
) -> int:
  viz = visualization_settings or {}
  payload = {
    "name": name,
    "description": description,
    "display": display,
    "collection_id": collection_id,
    "visualization_settings": viz,
    "dataset_query": {
      "type": "native",
      "native": {"query": sql, "template-tags": {}},
      "database": database_id,
    },
  }
  existing = find_card(base, session, name)
  if existing is not None:
    status, result = http_json(
      "PUT",
      f"{base}/api/card/{existing}",
      payload,
      session=session,
    )
    if status not in (200, 201):
      raise SystemExit(f"update card {name!r} failed: {status} {result}")
    print(f"updated card {name!r} id={existing} display={display}", flush=True)
    return existing

  status, result = http_json("POST", f"{base}/api/card", payload, session=session)
  if status not in (200, 201) or not isinstance(result, dict):
    raise SystemExit(f"create card {name!r} failed: {status} {result}")
  print(f"created card {name!r} id={result['id']} display={display}", flush=True)
  return int(result["id"])


def find_dashboard(base: str, session: str, name: str) -> dict | None:
  status, result = http_json("GET", f"{base}/api/dashboard", session=session)
  if status != 200:
    return None
  items = result if isinstance(result, list) else []
  for dash in items:
    if dash.get("name") == name:
      return dash
  return None


def ensure_public_dashboard(base: str, session: str, dash_id: int) -> str | None:
  """Enable public sharing and return public UUID for iframe embed in NevaDWH."""
  # Metabase 0.55+: endpoint is public_link (underscore), not public-link
  http_json(
    "PUT",
    f"{base}/api/setting",
    {"enable-public-sharing": True},
    session=session,
  )
  status, detail = http_json("GET", f"{base}/api/dashboard/{dash_id}", session=session)
  if status == 200 and isinstance(detail, dict):
    existing = detail.get("public_uuid")
    if existing:
      print(f"public uuid exists: {existing}", flush=True)
      return str(existing)
  status, result = http_json(
    "POST",
    f"{base}/api/dashboard/{dash_id}/public_link",
    {},
    session=session,
  )
  if status in (200, 201) and isinstance(result, dict) and result.get("uuid"):
    print(f"created public uuid: {result['uuid']}", flush=True)
    return str(result["uuid"])
  print(f"public_link failed: {status} {result}", flush=True)
  return None


def ensure_dashboard(
  base: str,
  session: str,
  *,
  name: str,
  collection_id: int,
  card_ids: list[int],
) -> int:
  existing = find_dashboard(base, session, name)
  if existing is not None:
    dash_id = int(existing["id"])
    print(f"dashboard exists {name!r} id={dash_id} — refresh layout", flush=True)
  else:
    status, result = http_json(
      "POST",
      f"{base}/api/dashboard",
      {
        "name": name,
        "description": "Три отчёта по витрине DWH: продажи, продажи×товары, товары",
        "collection_id": collection_id,
        "parameters": [],
      },
      session=session,
    )
    if status not in (200, 201) or not isinstance(result, dict):
      raise SystemExit(f"create dashboard failed: {status} {result}")
    dash_id = int(result["id"])
    print(f"created dashboard id={dash_id}", flush=True)

  # line chart taller; two bar charts below
  sizes_y = [9, 8, 8]
  dashcards = []
  row = 0
  for i, card_id in enumerate(card_ids):
    h = sizes_y[i] if i < len(sizes_y) else 8
    dashcards.append(
      {
        "id": -(i + 1),
        "card_id": card_id,
        "row": row,
        "col": 0,
        "size_x": 24,
        "size_y": h,
        "parameter_mappings": [],
        "visualization_settings": {},
      }
    )
    row += h

  status, result = http_json(
    "PUT",
    f"{base}/api/dashboard/{dash_id}",
    {
      "name": name,
      "description": "Три отчёта по витрине DWH: продажи, продажи×товары, товары",
      "parameters": [],
      "dashcards": dashcards,
      "collection_id": collection_id,
    },
    session=session,
  )
  if status not in (200, 201):
    print(f"dashboard PUT dashcards -> {status}, try /cards", flush=True)
    for i, card_id in enumerate(card_ids):
      h = sizes_y[i] if i < len(sizes_y) else 8
      st, res = http_json(
        "POST",
        f"{base}/api/dashboard/{dash_id}/cards",
        {
          "cardId": card_id,
          "row": sum(sizes_y[:i]),
          "col": 0,
          "size_x": 24,
          "size_y": h,
        },
        session=session,
      )
      print(f"  add card {card_id} -> {st} {res if st >= 400 else 'ok'}", flush=True)
  else:
    print("dashboard cards attached", flush=True)

  return dash_id


def ensure_reports(base: str, session: str, database_id: int) -> None:
  engine = env("METABASE_DWH_ENGINE", "postgres")
  if engine in ("mssql",):
    engine = "sqlserver"

  collection_id = ensure_collection(base, session)

  # Aggregated SQL — удобно для line/bar (не детальные строки)
  if engine == "sqlserver":
    sql_sales = """
SELECT
  [SaleDate] AS [Дата],
  SUM([Amount]) AS [Сумма],
  SUM([Qty]) AS [Количество]
FROM [target].[v_rpt_sales]
WHERE [SaleDate] IS NOT NULL
GROUP BY [SaleDate]
ORDER BY [SaleDate]
""".strip()
    sql_sales_products = """
SELECT TOP (15)
  COALESCE([ProductName], [ProductCode], N'Без названия') AS [Товар],
  SUM([Amount]) AS [Сумма],
  SUM([Qty]) AS [Количество]
FROM [target].[v_rpt_sales_products]
GROUP BY COALESCE([ProductName], [ProductCode], N'Без названия')
ORDER BY SUM([Amount]) DESC
""".strip()
    sql_products = """
SELECT TOP (15)
  COALESCE([Description], [Code], N'Без названия') AS [Товар],
  [Amount] AS [Сумма],
  [Qty] AS [Количество],
  [SaleCount] AS [Число продаж]
FROM [target].[v_rpt_products]
ORDER BY [Amount] DESC
""".strip()
  else:
    sql_sales = """
SELECT
  "SaleDate" AS "Дата",
  SUM("Amount") AS "Сумма",
  SUM("Qty") AS "Количество"
FROM target.v_rpt_sales
WHERE "SaleDate" IS NOT NULL
GROUP BY "SaleDate"
ORDER BY "SaleDate"
""".strip()
    sql_sales_products = """
SELECT
  COALESCE("ProductName", "ProductCode", 'Без названия') AS "Товар",
  SUM("Amount") AS "Сумма",
  SUM("Qty") AS "Количество"
FROM target.v_rpt_sales_products
GROUP BY COALESCE("ProductName", "ProductCode", 'Без названия')
ORDER BY SUM("Amount") DESC
LIMIT 15
""".strip()
    sql_products = """
SELECT
  COALESCE("Description", "Code", 'Без названия') AS "Товар",
  "Amount" AS "Сумма",
  "Qty" AS "Количество",
  "SaleCount" AS "Число продаж"
FROM target.v_rpt_products
ORDER BY "Amount" DESC
LIMIT 15
""".strip()

  viz_line = {
    "graph.dimensions": ["Дата"],
    "graph.metrics": ["Сумма"],
    "graph.x_axis.title_text": "Дата",
    "graph.y_axis.title_text": "Сумма",
    "graph.show_values": False,
  }
  viz_bar_products = {
    "graph.dimensions": ["Товар"],
    "graph.metrics": ["Сумма"],
    "graph.x_axis.title_text": "Товар",
    "graph.y_axis.title_text": "Сумма",
    "graph.show_values": True,
  }
  viz_bar_catalog = {
    "graph.dimensions": ["Товар"],
    "graph.metrics": ["Сумма"],
    "graph.x_axis.title_text": "Товар",
    "graph.y_axis.title_text": "Сумма",
    "graph.show_values": True,
  }

  card_sales = create_card(
    base,
    session,
    name="1. Продажи",
    description="Динамика суммы продаж по дням (target.v_rpt_sales)",
    database_id=database_id,
    sql=sql_sales,
    display="line",
    collection_id=collection_id,
    visualization_settings=viz_line,
  )
  card_sp = create_card(
    base,
    session,
    name="2. Продажи по товарам",
    description="Топ-15 товаров по сумме продаж (target.v_rpt_sales_products)",
    database_id=database_id,
    sql=sql_sales_products,
    display="bar",
    collection_id=collection_id,
    visualization_settings=viz_bar_products,
  )
  card_prod = create_card(
    base,
    session,
    name="3. Товары / продукты",
    description="Топ-15 товаров витрины по сумме (target.v_rpt_products)",
    database_id=database_id,
    sql=sql_products,
    display="row",
    collection_id=collection_id,
    visualization_settings=viz_bar_catalog,
  )

  ensure_dashboard(
    base,
    session,
    name="Продажи и товары",
    collection_id=collection_id,
    card_ids=[card_sales, card_sp, card_prod],
  )
  # public link for NevaDWH iframe (/Reports)
  dash = find_dashboard(base, session, "Продажи и товары")
  if dash is not None:
    uuid = ensure_public_dashboard(base, session, int(dash["id"]))
    public_base = env("METABASE_PUBLIC_BASE_URL", env("MB_SITE_URL", "http://bi.localhost")).rstrip("/")
    if uuid:
      print(f"public dashboard: {public_base}/public/dashboard/{uuid}", flush=True)
  print(
    "Готово: «Отчёты DWH» → «Продажи и товары» (линия + столбцы + горизонтальные бары)",
    flush=True,
  )


def demo_reports_enabled() -> bool:
  """Create v_rpt_* cards only when METABASE_DEMO=true (IsDemo generation)."""
  return env("METABASE_DEMO", "false").strip().lower() in ("1", "true", "yes")


def main() -> int:
  base = env("MB_URL", "http://metabase:3000").rstrip("/")
  wait_ready(base)
  do_initial_setup(base)
  session = login(base)
  ensure_locale(base, session)
  db_id = ensure_database(base, session)
  # give sync a moment (native SQL works without it, but helps Browse)
  time.sleep(3)
  if demo_reports_enabled():
    ensure_reports(base, session, db_id)
  else:
    print("METABASE_DEMO!=true: admin + DWH database only (no demo report cards)", flush=True)
  return 0


if __name__ == "__main__":
  try:
    sys.exit(main())
  except SystemExit:
    raise
  except Exception as exc:  # noqa: BLE001
    print(f"FATAL: {exc}", flush=True)
    sys.exit(1)
