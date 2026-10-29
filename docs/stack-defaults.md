# Stack defaults

New McWestling products use the McWestling Neon org for Postgres, keeping one database provider across products. This default follows the [Cloudflare-only stack decision (DO-1388)](https://linear.app/mcwestling/issue/DO-1388/revisit-database-hosting-for-a-cloudflare-only-stack) and the [Piumosso hosting decision (DO-1390)](https://linear.app/mcwestling/issue/DO-1390/decide-whether-piumosso-stays-on-railway).

Opal is the exception: it stays on Railway Postgres for maintenance until BSO moves onto Piumosso. Railway can be retired after that move.
