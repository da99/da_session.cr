
da\_session.cr
==============

My personal shard I use for Crystal web apps.
It's set for Redis and `opinionated` for my
needs only.

I forked `kemal-session`, then I rewrote the
code for simplicity: one module.
For configuration, you just overwrite
methods:

```Crystal
  def secret
    # your string here
  end

  def timeout
    # your Time::Span instance here.
  end

  # etc.
```
