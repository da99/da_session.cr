
Reference:
================

* Timing attacks:
  * https://codahale.com/a-lesson-in-timing-attacks/
  * http://devdocs.io/crystal/api/0.24.1/crypto/subtle#constant_time_compare(x,y):Bool-class-method

da\_session.cr
==============

My personal shard I use for Crystal web apps.
It's `opinionated` for my needs only.

I forked `kemal-session`, then I rewrote the
code for simplicity. At this point, there is
very little similarity with `kemal-session`.

```Crystal
  my_session = DA_Session.new(
      http_context,
      secret:      ENV["my_secret"],
      secure:      true, # HTTPS only?
      lifespan:    1.week,
      cookie_name: "my_cookie_name",
      domain:      nil,
      path:        "/"
  )

  my_session.load # Retrieve from browser if possible.

  if my_session.in_client? # Cookie is in the browser.
    sess_id = my_session.id
    if my_session.deleted?
      # The session was invalid
      # Destroy the session in your own data store.
    else
      # Retrieve from your data store
    end
  else # Cookie doesn't exist.
    my_session.save
    # Create a new session.
    # A new session id is created.
    if my_session.new?
      # :new? returns true if new cookie is being sent to browser.
      sess_id = my_session.id
      # Save to your data store (Redis, PG, MariaDB, etc.)
    end
  end
```

