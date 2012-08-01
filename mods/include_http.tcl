package require http
package require tls

::http::register https 443 ::tls::socket

proc include_http_base64 {str} {
  if {![catch {binary encode base64 $str} res]} {
    return $res
  }
  # binary encode didn't work (needs tcl8.6)... try with base64 pkg
  if {[info commands base64::encode] eq ""} {
    package require base64
  }
  return [base64::encode $str]
}

# args:
#   -auth-user str: specify user for basic http authentication.
#   -auth-pass str: specify password for basic http authentication.
#   -vars list: specify a list of vars to copy to the safe interpreter.
#   -cachefile str: filename used for cache...
#   -cachesecs int: omit http request if filename is not this number of seconds old.
#   -procs list: specify a list of additionals procs allowed at the safe interpreter.
#   -host-opts list: list of allowed options in host calls from interpreter...
#   -safe bool: if false don't eval the code in a safe interpreter (default true)
proc include_http {url args} {
  if {[llength $args]%2} {
    error "wrong # of args: should be \"include_html url ?options?\""
  }
  set opts [dict create \
      "-headers" {} \
      "-procs" {} \
      "-vars" {} \
      "-procs" {} \
      "-host-opts" {} \
      "-cachefile" "~/.ssh/sshfu/include_http-[string map {/ _} [include_http_base64 $url]]" \
      "-cachesecs" 60 \
      "-safe" true]
  foreach {key val} $args {
    dict set opts $key $val
  }
  if {[dict exists $opts "-auth-user"]} {
    set user [dict get $opts "-auth-user"]
    set pass [dict get $opts "-auth-pass"]
    set res [include_http_base64 $user:$pass]
    dict lappend opts "-headers" Authorization "Basic $res"
  }
  set cachefile [dict get $opts "-cachefile"]
  # make request
  set successful true
  if {[file exists $cachefile] && ([clock seconds]-[dict get $opts "-cachesecs"]
	< [file mtime $cachefile])} {
    # no need to make request...
    set successful false; # because there was no request in first place
  } elseif {[catch {http::geturl $url -headers [dict get $opts "-headers"]} tok]} {
    puts stderr "warning: http error: $tok"
    set successful false
  } elseif {![string match {2??} [http::ncode $tok]]} {
    puts stderr "warning: http code not 2xx: [http::ncode $tok]: [http::code $tok]"
    http::cleanup $tok
    set successful false
  } else {
    # only match group of lines starting with # @@@BEGIN-SSHFU@@@
    set re {(?:^|\n) *#+ *@@@ *BEGIN-SSHFU *@@@ *}
    # add a negative look ahead with # @@@END-SSHFU@@@ line
    # to understand the regexp read: man re_syntax
    # and: http://en.wikipedia.org/wiki/Parsing#Lookahead
    append re {((?:(?! *#+ *@@@ *END-SSHFU *@@@)[^\n]*.?)*)}
    set matches [regexp -all -inline $re [http::data $tok]]
    # in other words, this matches groups of lines with the format:
    # # @@@BEGIN-SSHFU@@@
    # config config config...
    # more config
    # # @@@END-SSHFU@@@
    http::cleanup $tok
    set tmp_matches {}
    foreach {fullmatch match} $matches {
      lappend tmp_matches $match
    }
    set code [join $tmp_matches "\n"]
    set fd [open $cachefile w]
    puts $fd $code
    close $fd
  }
  # read cachefile...
  if {!$successful && [catch {
    set fd [open $cachefile r]
    set code [read $fd]
    close $fd
  } res]} {
    puts stderr "warning: couldn't load cache: $res"
    return
  }
  # now, time to run the code in a safe interp
  if {[dict get $opts "-safe"]} {
    set interp [interp create -safe]
    foreach var [dict get $opts "-vars"] {
      interp eval $interp set $var [uplevel set $var]
    }
    foreach proc [dict get $opts "-procs"] {
      interp alias $interp $proc {} $proc
    }
    interp alias $interp host {} include_http_restricted_host [dict get $opts "-host-opts"]
    interp eval $interp $code
    interp delete $interp
  } else {
    #unsafe
    uplevel $code
  }
}

proc include_http_restricted_host {allowed hostname args} {
  set unsafere {[^a-zA-Z+%/=?@^_,.:0-9-]}
  if {[regexp $unsafere $hostname]} {
    puts stderr "warning: invalid char in hostname, ignoring host"
    return
  }
  set realargs {}
  foreach {opt val} $args {
    set val [string map {"\n" "" "\r" "" "\0" "" "\\" ""} $val]
    if {[lsearch -exact $allowed $opt] < 0} {
      puts stderr "warning: option \"$opt\" not allowed, used on host \"$hostname\" (from include_http), ignoring host"
      return
    }
    if {$opt eq "agent"} {
      if {$val ne "yes" && $val ne "no"} {
	puts stderr "warning: invalid value for $opt option, use yes or no, ignoring host"
	return
      }
    }
    if {[lsearch -exact {address user gw port} $opt]} {
      # forbid spaces, control characters, backslashes
      if {[regexp $unsafere $val]} {
	puts stderr "warning: invalid value for $opt option, use only allowed chars. Ignoring host"
	return
      }
    }
    lappend realargs $opt $val
  }
  host $hostname {*}$realargs
}

