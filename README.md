
da\_session.cr
==============

My personal shard I use for Crystal web apps.
It's `opinionated` for my needs only.

I forked `kemal-session`, then I rewrote the
code for simplicity. At this point, there is
very little similarity with `kemal-session`.

```Crystal
  my_session = DA_Session.new(http_context, secret: ENV["my_secret"], lifespan: 1.week, ...)
  my_session.load # retrieve from browser
  if my_session.in_client?
    sess_id = my_session.id
    # Retrieve from your data store
  else
    my_session.save
    if my_session.new?
      sess_id = my_session.id
      # Save to your data store (Redis, PG, MariaDB, etc.)
    end
  end
```

