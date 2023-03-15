I'm trying to understand when and why some interval joins become regular joins instead. In `test.sql`, the temporary view `suspiciousOrders` is an interval join unless one adds another temporary view, `filteredResults`. To see this:

```sh
docker compose up
docker exec -it flink-debug-flink-1 bash
/opt/flink/bin/sql-client.sh -f /test/test.sql
```

Then visit http://localhost:8081 and view the completed `collect` job. In the first case, the final node is an IntervalJoin:

```
[13]:IntervalJoin(joinType=[InnerJoin], windowBounds=[isRowTime=true, leftLowerBound=-86400000, leftUpperBound=0, leftTimeIndex=0, rightTimeIndex=1], where=[((product = product0) AND (customer = customer0) AND (ts &gt;= (cancel_ts - 86400000:INTERVAL DAY)) AND (ts &lt;= cancel_ts))], select=[ts, orderId, customer, product, quantity, order_ts, cancel_ts, product0, customer0, cancel_quantity])
+- [14]:Calc(select=[orderId, customer, product, quantity AS order_quantity, cancel_quantity, order_ts AS large_ts, ts AS small_ts, cancel_ts])
   +- [15]:ConstraintEnforcer[NotNullEnforcer(fields=[order_quantity, cancel_quantity])]
      +- Sink: Collect table sink
```

Next comment out `select * from suspiciousOrders;` replace with `select * from filteredResults;` rerun and revisit the web page:

```
 [13]:Join(joinType=[InnerJoin], where=[((product = product0) AND (customer = customer0) AND (ts &gt;= (cancel_ts - 86400000:INTERVAL DAY)) AND (ts &lt;= cancel_ts) AND (ts &gt; order_ts))], select=[ts, orderId, customer, product, quantity, order_ts, cancel_ts, product0, customer0, cancel_quantity], leftInputSpec=[NoUniqueKey], rightInputSpec=[NoUniqueKey])
+- [14]:Calc(select=[orderId, customer, product, quantity AS order_quantity, cancel_quantity, order_ts AS large_ts, ts AS small_ts, cancel_ts])
   +- [15]:ConstraintEnforcer[NotNullEnforcer(fields=[order_quantity, cancel_quantity])]
      +- Sink: Collect table sink
```