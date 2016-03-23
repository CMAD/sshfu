# Basic examples

## Example 1: Everything accesible.

```
         (internet)
           |  | |
           |  | +------------+
     +-----+  +--+           |
     |           |...fqdn    |192.51.100.42
+----------+  +-------+  +-------+
|mycomputer|  |server1|  |server2|
+----------+  +-------+  +-------+
```

Just add the servers one after another:

```tcl
host server1 address server1.this.is.a.fqdn
host server2 addres 198.51.100.42
```

but maybe we need to use a different private key to connect to server1, and want a different default user to connect to server2, then the configuration changes to:

```tcl
host server1 address server1.this.is.a.fqdn key foo_rsa
host server2 addres 198.51.100.42 user jsmith
```

## Example 2: Indirect servers.

Now the've told us that server1 is a balancer, and in fact it's connected to two non-public work web servers. Btw: server2 is also connected to a database server. Let's draw them:
```
         (internet)
           |  | |
           |  | +------------+
     +-----+  +--+           |
     |           |...fqdn    |192.51.100.42
+----------+  +-------+  +-------+
|mycomputer|  |server1|  |server2|
+----------+  +-------+  +-------+
                |10.3.2.1    |10.0.0.33
               (switch)      |
             .101|   |.102   |10.0.0.42
            +----+ +----+   +--+
            |web1| |web2|   |db|
            +----+ +----+   +--+
```

So let's update the configuration as well:

```tcl
host server1 address server1.this.is.a.fqdn key foo_rsa
host server1-web1 address 10.3.2.101 gw server1 key foo_rsa
host server1-web2 address 10.3.2.102 gw server1 key foo_rsa

host server2 addres 198.51.100.42 user jsmith
host server2-db address 10.0.0.42 gw server2 user root
```

Since in our example for every server behind server1 we must use key foo\_rsa, we can unify that instead of writing `key foo_rsa` each and every time. We use the `with` command for that:

```tcl
with key foo_rsa {
  host server1 address server1.this.is.a.fqdn
  host server1-web1 address 10.3.2.101 gw server1
  host server1-web2 address 10.3.2.102 gw server1
}

host server2 addres 198.51.100.42 user jsmith
host server2-db address 10.0.0.42 gw server2 user root
```

## Example 3: Variable CONTEXTs.

The owner of server1 told us that on Mondays we should go to that company, and work connected to the internal switch behind server1.

```
         (internet)
           |  | |
           |  | +------------+
 +---------+  +--+           |
 |[the other     |           |
 | weekdays]     |...fqdn    |192.51.100.42
+----------+  +-------+  +-------+
|mycomputer|  |server1|  |server2|
+----------+  +-------+  +-------+
  |[mondays]    |10.3.2.1    |10.0.0.33
  +------------(switch)      |
             .101|   |.102   |10.0.0.42
            +----+ +----+   +--+
            |web1| |web2|   |db|
            +----+ +----+   +--+
```

To do this we may want to have automatic CONTEXT detection based on parameters like the default gateways or the assigned addresses. Or maybe we want that the CONTEXT to vary according to the weekday. [This tutorial](context.md) may help.

Once CONTEXT is determined we can advance with the configuration, now dependant on that variable:

```tcl
with key foo_rsa {
  inside server1 {
    host server1      address 10.3.2.1
    host server1-web1 address 10.3.2.101
    host server1-web2 address 10.3.2.102
  } otherwise {
    host server1 address server1.this.is.a.fqdn
    host server1-web1 address 10.3.2.101 gw server1
    host server1-web2 address 10.3.2.102 gw server1
  }
}

host server2 addres 198.51.100.42 user jsmith
host server2-db address 10.0.0.42 gw server2 user root
```

**TODO**: Add more examples later.
