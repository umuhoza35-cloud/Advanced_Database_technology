SELECT 
    activity.pid,
    activity.usename,
    activity.state,
    activity.query,
    activity.wait_event_type,
    activity.wait_event,
    blocking.pid AS blocking_pid
FROM pg_stat_activity activity
LEFT JOIN pg_stat_activity blocking ON blocking.pid = ANY(pg_blocking_pids(activity.pid))
WHERE activity.pid != pg_backend_pid()
  AND activity.state != 'idle'
ORDER BY activity.pid;
