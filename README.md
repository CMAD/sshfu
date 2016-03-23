# sshfu: ~/.ssh/config manager.

This Tcl script provides an alternative line-by-line syntax for ~/.ssh/config that is a little easier on the eyes.

When you have more than two hosts on you configuration it gets a little verbose for simple things, and here is where this syntax helps.

This is what the syntax looks like:

```tcl
host server address server.test user root
host grimalkin address 192.168.1.1 gw server user cmad
host vm1 address 10.10.1.1 gw grimalkin
```

And this what it will compile into:

```
Host server
  HostName server.test
  User root

Host grimalkin
  HostName 192.168.1.1
  ProxyCommand ssh server -W %h:%p
  User cmad

Host vm1 
  HostName 10.10.1.1
  ProxyCommand ssh grimalkin -W %h:%p
```

If it finds an already existing ~/.ssh/config, it will make a copy on ~/.ssh/original_ssh_config, and try to import your configuration.

sshfu will fire $EDITOR on ~/.ssh/sshfu/routes and when you exit, compile the resulting configuration along with ~/.ssh/sshfu/ssh_config.head and ~/.ssh/sshfu/ssh_config.tail into your actual ~/.ssh/config.

It shouldn't do any harm to say but, this script is garbage-in garbage-out, which means, if yo put a typo in the sshfu config file, expect one in your ~/.ssh/config

Maybe latter I will provide some options, like re-import from ~/.ssh/config, make it more clean, etc. For the time being, it's just something I use, and hopefully it maybe of some use to you.

An important feature, in other words a side effect of using a programming language for the configuration, is that we can dinamically choose the parameters of the hosts (like the gw) depending on external information. For example using an additional gw when we are at home to reach a remote server. More info [here](docs/context.md). It can also detect infinite loop cycles.

Besides any other normal Tcl command, this script provides the `inside` and `with` commands, inside matches against a CONTEXT variable and is usefull for changing gateways or projects for example, with 'with' you can apply defaults to a block, and you can put tags, so that you can parse the sshfu routes as documentation, or group them for diagrams.

```tcl
inside home or public {
  with gw office_firewall {
    host foo address 192.168.5.4
    bla bla bla
  }
} otherwise {
  host foo address 192.168.5.4 tag webserver
  bla bla bla

  with tags {blah blah} {
    blah blah blah
  }
}
```

Bye.
