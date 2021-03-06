# CONTEXT detection.

This is a short tutorial explaining how to create a get_context.tcl; file that after gather some external information is able to determine whether you are for instance on your home, connected to your work's wifi or using a VPN; setting CONTEXT accordingly.

After presenting a few basic common tools, we will connect them to create the particular configuration suited to each and everyone of us.

Remember that sshfu config files are just Tcl scripts with added functionality. In this document we will use `if`/`elseif`/`else` and comparisons extensively, so you may glance at this [Tcl tutorial](https://www.tcl.tk/man/tcl8.5/tutorial/tcltutorial.html) before continuing for some basic additional information.

## Tool 1: Reading a file.

In the UNIX/Linux world almost everything is represented by a file, and we normally need to read those files to retrieve the current running state of interfaces and everything else. Let's make a _function that reads a file_

```tcl
proc readfile {filename} {
  set fd [open $filename r]
  set content [read -nonewline $fd]
  close $fd
  return $content
}
```

We can then easily compare a file against a constant:

```tcl
if {[readfile "/proc/sys/net/ipv4/ip_forward"] eq "1"} {
  puts "ip forward enabled"
} else {
  puts "ip forward disabled"
}
```

## Tool 2: Grepping.

Maybe we need to check if there's a line in a block of text that matches a given [regular expression](http://www.tcl.tk/man/tcl/TclCmd/re_syntax.htm). A simple implementation could be:

```tcl
proc grepcontent {text re} {
  foreach line [split $text "\n"] {
    if {[regexp -- $re $line]} {
      return true
    }
  }
  return false
}
```

and a simple usage example:

```tcl
if {[grepcontent [readfile "/etc/passwd"] {^fran:}]} {
  puts "there's a user called fran"
} elseif {[grepcontent [readfile "/etc/passwd"] {^cma:}]} {
  puts "there's no user called fran, but there's a user called cma"
} else {
  puts "there's no cma nor fran user"
}
```

Plus another not so simple but useful example:

```tcl
if {[grepcontent [readfile "/proc/net/if_inet6"] {^2001129102790000caf733fffe80e01c.*wlan0}]} {
  # wlan0 has ipv6 address: 2001:1291:279::222:68ff:feb7:df3f
  puts "we are home!"
}
```

## Tool 3: Checking default IPv4 gw on linux.

With these tools we can begin building other higher level ones like, for instance, a function that returns true if the current default gateway is the specified one in the specified regex of interfaces.

```tcl
proc is_default_ipv4_gw {iface_regex gw} {
  set octets [split $gw "."]
  set hexgw [format {%4$02X%3$02X%2$02X%1$02X} {*}$octets]
  grepcontent [readfile /proc/net/route] "^($iface_regex)\t00000000\t$hexgw"
}
```

that may be used something like this:

```tcl
if {[is_default_ipv4_gw {eth0|eth1|wlan0} 10.71.1.51]} {
  puts "yes, the default gw is 10.71.1.51 and it's on eth0, eth1 or wlan0"
}
```

## Tool 4: Running a command.

Another commonly used tool, although not as fast as reading a file, is to execute an external command. Also beware that the output of those tools sometimes change between different operating systems, or even different versions of the same OS. They also change according to the locale: so better **be careful**.

Here we will use the tricky Tcl's `exec` command for this. Since this command throws an error if the executed command fails or if there's non empty output to stderr, we need to handle those cases:
* Adding `2>/dev/null` ignores the stderr output.
* Using `catch` to capture errors. If the exec command works, then its output to stdout is kept into `res`.

```tcl
set env(LANG) C; # sort of localization disabling.

if {[catch {exec ip route show 2>/dev/null} res]} {
  # failed:
  puts "exec command failed: $::errorInfo"
} elseif {[grepcontent $res {^default via 192\.168\.1\.1 }]} {
  puts "default gateway is 192.168.1.1!"
} elseif {[grepcontent $res {^default }]} {
  puts "there's a default route, but 192.168.1.1 is not its gateway"
} else {
  puts "there's no default gateway... disconnected from IPv4 internet?"
}
```

## Tool 5: Days of the week.

Why not? Maybe we want a different configuration for weekdays and another for weekends:

```tcl
if {[clock format [clock seconds] -format %a] in {Sat Sun}} {
  puts "Weekend!!!"
}
```

## Tool 6: Querying the Windows' registry.

Only available on Microsoft Windows, is the [registry](https://www.tcl.tk/man/tcl8.0/TclCmd/registry.htm) command that can be used for a plethora of usages, like the following.

```tcl
if {[registry get "HKEY_LOCAL_MACHINE\\System\\CurrentControlSet\\Services\\Tcpip\\Parameters\\Interfaces\\{4B4929AF-62C1-358F-BEF0-68B9B3EE49E3}" DhcpIPAddress] eq "10.71.1.43"} {
  puts "this not-tested test probably shows us that the interface 4B4929AF-62C1-358F-BEF0-68B9B3EE49E3 has obtained the ip address 10.71.1.43 via DHCP"
}
```

## Putting it all together.

Given these tools, we just need to create a file like `~/.ssh/sshfu/get_context.tcl` with our logic to detect where are we located, based on the output of files and commands. In this file just include the procedures like `readfile` and `grepcontent` (or anyother you like!), and then write a huge chain of `if`/`elseif`/`elseif`/.../`elseif`/`else` with the checks and assigning the corresponding value to the `CONTEXT` global variable.

Here comes a basic `get_context.tcl` example:

```tcl
proc grepfile {filename re} {
  set fd [open $filename r]
  set text [read $fd]
  close $fd
  foreach line [split $text "\n"] {
    if {[regexp -- $re $line]} {
      return true
    }
  }
  return false
}

if {[grepfile "/proc/net/if_inet6" {^2001129102790000caf733fffe80e01c.*wlan0}]} {
  # wlan0 has ipv6 address: 2001:1291:279::222:68ff:feb7:df3f
  set CONTEXT home
} elseif {[grepfile /proc/net/route "^(eth|wlan)0\t00000000\t[format {%4$02X%3$02X%2$02X%1$02X} 10 71 1 51]"]} {
  # default ipv4 gw is 10.71.1.51
  set CONTEXT home
} elseif {[grepfile "/proc/net/route" {^(eth|wlan)0\t00000000\t73(01|3C)A8C0}]} {
  # default ipv4 gw is 192.168.1.115 or 192.168.60.115
  set CONTEXT office
} elseif {[grepfile "/proc/net/route" {^(eth|wlan)0\t00000000\t01D8A8C0}]} {
  # default ipv4 gw is 192.168.216.1
  set CONTEXT factory
} else {
  puts stderr "Warning: Context not detected, \"other\" assumed."
  set CONTEXT other
}
```

Be creative! Adapt these tools to your liking!

Then, just source `get_context.tcl` by adding the following line before any host definition on the sshfu main configuration:

```tcl
source ~/.ssh/sshfu/get_context.tcl
```

## Auto-update.

Remember that the `.ssh/config` file will only be generated when we update the configuration running the `sshfu` script. That's why it's also important to automatically run this script with the DONT_EDIT variable set when a pertinent change happens, for instance via crontab if CONTEXT depends on the date/time and via if-up.d (on debian based systems) if it depends on the network state.

A simple way to do this on Debian based systems is to add a `/etc/network/if-up.d/sshfu` file with:

```bash
#!/bin/sh

su - myuser -c 'DONT_EDIT=1 ~/bin/sshfu'
```

Or on systems running NetworkManager in general by adding a `/etc/NetworkManager/dispatcher.d/02sshfu` with:

```bash
#!/bin/sh

if [ -z "$1" ]; then
  echo "$0: called with no interface" 1>&2
  exit 1;
fi

if [ "$2" = up -o "$2" = vpn-up ]; then
  su - myuser -c 'DONT_EDIT=1 ~/bin/sshfu'
fi
```

Presto!
