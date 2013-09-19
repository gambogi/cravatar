# cravatar

A simple, LDAP-backed avatar service.

# How can I use it???

```html
<img src="http://avatar.csh.rit.edu/6dcadc90-1739-102d-9957-d3de3ed42b90.jpg">
```

where that big long string is the entryUUID of the user.

# Wow, that was easy! How do I deploy?

```bash
cpanm --install-deps .
plackup -E production -s Starman --workers 10 -p 5000 -a bin/app.pl
```

The first line installs the deps, the second line starts up Starman,
a pure-perl web server, and runs the app in the production environment.
The deployment-specific config files are in environments/\*.yml

ProxyPass with apache/nginx.

# It's a little slow

Happens. But you're in luck, as this makes use of memcached if it's
available. Start up memcached, firewall off the port, and you're good
to go.
