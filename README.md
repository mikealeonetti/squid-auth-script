Introduction
============

As we all know you can't use proxy auth with transparent proxies (now also called interception proxies). So, an alternate method needs to be used to authenticate. Luckily, Squid allows you to use custom authentication programs. This setup gives you blocked sites. But on the access denied page the user gets a link to allow web access to any website for a given amount of time. It was made to mimic the behaviour of Sonicwall and like routers. And of course in a domain setting with LDAP/ActiveDirectory, LDAP/ActiveDirectory already has all of the user names and passwords.

Of course, multiple ways of authentication can be added to the script. Currently the script supports user lookups in LDAP, ActiveDirectory, and htpasswd files. The script also supports different levels of access for different groups in LDAP/ActiveDirectory/htgroup files.

You can see [my video on YouTube](http://www.youtube.com/watch?v=-HseheODcNk) for a quick demonstration of how it works.

Note
----

This is **not** real *proxy authentication*. When you decide to use transparent/interception proxy mode with Squid real proxy authentication gets thrown out of the window. The same limitations apply. For example, you will not be able to proxy control SSL websites. They will be outside of your control using Squid.

This authentication is IP based. It uses the IPs of the machines in the internal network. Therefore authenticating based on users logged into the same machine also becomes impossible. I've also found that cookie authentication is not a good method to solve this problem either. So IP based authentication is still the best way to go about it when dealing with transparent/interception proxies.

Although your mileage may vary.

Prerequisites
-------------

This article assumes that you have MySQL setup, the machine is the router with iptables installed and configured, squid is already installed with it mostly configured and working, LDAP is installed and configured, and Apache is also installed and configured.

Screen shots
------------

<img src="Authentication-screen1.png" title="fig:Login form." alt="Login form." width="300" /> <img src="Authentication-screen2.png" title="fig:Redirect form after login." alt="Redirect form after login." width="300" />

Installation
============

Downloading and installing
--------------------------

1.  Extract the archive into a good working directory.
2.  Place **squidpasswd** (the Perl/CGI script that serves the form) into your cgi-bin directory (EG /var/www/localhost/cgi-bin, /var/lib/cgi-bin, etc). Make sure it is executable by all (chmod +x squidpasswd).
3.  Put the **squidauth** (the script called by Squid) into /usr/local/bin and make sure it is executable to all or at least the Squid user (chmod +x squidauth will do all).
4.  Place the **squid** directory which contains the actual login form HTML into your web directory (usually /var/www/localhost/htdocs, /var/www/, etc). *Remember the path you put it in!*

Configuring
-----------

### squidpasswd

We must modify this file to match your authentication method, directory structure, and set the allowed groups.

First let's **set the allowed groups**.

    # This is a list of the groups needed.
    # This can optionally be one group but if the user is not a member of this group he will be denied.
    my @groups_accepted = ( "Squid Admin", "knights" );

Set this to the groups that will be able to authenticate. *These are just the groups that have the ability to be authenticated.* That means that if a user is not a part of these groups he will not be able to log in. We do not set the separate permissions for websites at this step.

We also need to set **the auth type**. Here we can set if we are going to use LDAP to authenticate users or htaccess. So find the following.

    m# Set the auth type here (accepted options, "ldap" and "htpasswd")
    my $auth_type = "ldap";

For authentication using passwd files set this to *passwd*. **Also note** that if you are *not* using passwd files to authenticate you can comment this out these lines near the top.

    use HTTPD::Authen;
    use HTTPD::GroupAdmin;

Set **the template file**. Find the following near the top.

    # The path to the HTML template file for logins
    my $template_file = "/var/www/localhost/htdocs/squid/login.html";

Set this to the absolute path of the template file as listed above.

Set **the MySQL options**

    ########
    # MySQL options
    ########
    my $mysql_host = "localhost";
    my $mysql_database = "squidauth";
    my $mysql_username = "squidauth";
    my $mysql_password = "squidauth";

**If you are using LDAP to authenticate** set the following options.

    ########
    # Auth type "ldap" options
    ########
    # LDAP server and directory opts
    my $host = "localhost";
    my $suffix = "dc=directory,dc=server";
    my $usersdn = "ou=People,$suffix";
    my $groupdn = "ou=Group,$suffix";
    # The bing string required to auth the user with LDAP
    # OpenLDAP: uid=%s,$usersdn
    # ActiveDirectory: DOMAIN\\%s
    # Note that %s will be filled in with the user later
    my $bind_string = "uid=%s,$usersdn";
    # The group field that relates fo the user
    # OpenLDAP: memberUid
    # ActiveDirectory: member
    my $group_relation_field = "memberUid";
    # The field used in the user to match up the user to the directory
    # OpenLDAP: uid
    # ActiveDirectory: distinguishedName
    my $relation_attribute = "uid";
    # Field to look up the username
    # OpenLDAP: uid
    # ActiveDirectory: sAMAccountName
    my $username_field = "uid";

Please note that in the comments it also describes how to get the script to work with ActiveDirectory. The script works with both.

If instead you are **using htpasswd files to authenticate**, modify the following options.

    ########
    # Auth type "htpasswd" options
    ########
    # The paths to the htpasswd and htgroup files
    my $htpasswd_path = "/home/mike/squidproject/htpasswd";
    my $htgroup_path = "/home/mike/squidproject/htgroup";
    # The type of database, one of 'DBM', 'Text', or 'SQL'
    my $dbtype = "Text";
    # HTTP server name (one of 'nsca' or 'apache')
    my $servername = "apache";

$htpasswd\_path and $htgroup\_path need to be set to the precise path of htpasswd and htgroup files. Groups must be specified for the script to work since the script is on a group-based model. To create users with htpasswd use the program *htpasswd*. htgroup files are simply plain files written like this.

    knights: mike tom
    squid: jesse

### squidauth

The squidauth script is exclusively called Squid when pages are requested and does not require much configuration. Just make sure the correct MySQL database and user options are set near the top.

    ## MySQL info
    my $mysql_host = 'localhost';
    my $mysql_user = 'squidauth';
    my $mysql_pass = 'squidauth';
    my $mysql_db = 'squidauth';

### MySQL database setup (tables.sql)

This table is used to store the users and groups. Make sure tables.sql is in the current directory.

    # mysql
    mysql> CREATE DATABASE squidauth;
    mysql> GRANT ALL PRIVILEGES ON squidauth.* TO squidauth@localhost IDENTIFIED BY 'squidauth';
    mysql> USE squidauth;
    mysql> \. tables.sql
    mysq> quit

Note that if you want to use another table name or username/pass you have to change the auth entries in the scripts.

### Configuring the squid webpage

If you put the *squid* directory containing the HTML and CSS files into the root directory of your web page, chances are you won't have to change these options. Just in case you do, let me point out where the options need to be changed in the HTML and CSS for things to work.

#### login.html

Change the line that includes the CSS.

    <link href="/squid/login-box.css" rel="stylesheet" type="text/css" />

And the line that shows the button image.

    <input type="image" src="/squid/images/login-btn.png" width="103" :eight="42" style="margin-left:90px;" border="0" alt="Login" /></form>

#### login-box.css

Just change the line that sets the background URL.

    background: url(/squid/images/login-box-backg.png) no-repeat left top;

### Configuring Squid

Now make these changes in the /etc/squid/squid.conf (or /etc/squid3/squid.conf depending on your distro).

    external_acl_type time_squid_auth ttl=5 %SRC /usr/local/bin/squidauth knights

    # Put these with your ACLs
    acl interval_auth external time_squid_auth

    # Put this at the appropriate place and change it for your configuration
    http_access allow localnet interval_auth

**Note**: keep in mind that *localnet* should be either defined with your localnet or replaced with the acl IP src that you want. For example, my *localnet* is defined as:

    acl localnet src 192.168.1.0/24

And it should be defined *above* in your squid.conf where you reference it.

Note above the word **knights** in the config. Replace this with the group (singular) that you wish to authenticate for. You can use multiple groups for multiple levels of authentication.

### Additional iptables configurations

Since the script uses the IP of the machine to tell whether or not it's authenticated, make sure your transparent proxy REDIRECT in iptables excludes access to machines on the local network (mainly the server that has the squidpasswd script running)

    # iptables -A PREROUTING -t nat -i eth1 -p tcp --dport 80 -m iprange ! --dst-range 192.168.1.1-192.168.1.254 -j REDIRECT --to-port 3128

Of course replace eth1 with the interface associated with the local network and 192.168.1.1-192.168.1.254 with your network.

### Miscellaneous configurations

To change the “Access Denied” webpage and add a link to the squidpasswd script either modify the Access Denied page in /usr/share/squid/errors/ (I found mine in /usr/share/squid/errors/templates/ERR\_ACCESS\_DENIED for English) or create a custom error script and tell Squid to use it for that ACL.

Common issues
=============

Can't locate HTTPD/Authen.pm
----------------------------

You may get something like the following.

    Can't locate HTTPD/Authen.pm in @INC (@INC contains: /etc/perl /usr/lib64/perl5/site_perl/5.12.4/x86_64-linux /usr/lib64/perl5/site_perl/5.12.4 /usr/lib64/perl5/vendor_perl/5.12.4/x86_64-linux /usr/lib64/perl5/vendor_perl/5.12.4 /usr/lib64/perl5/site_perl /usr/lib64/perl5/vendor_perl/5.12.3/x86_64-linux /usr/lib64/perl5/vendor_perl/5.12.3 /usr/lib64/perl5/vendor_perl/5.12.2/x86_64-linux /usr/lib64/perl5/vendor_perl/5.12.2 /usr/lib64/perl5/vendor_perl /usr/lib64/perl5/5.12.4/x86_64-linux /usr/lib64/perl5/5.12.4 /usr/local/lib/site_perl .) at ./serverhome/squidproject/squidpasswd line 23, <DATA> line 558.
    BEGIN failed--compilation aborted at ./serverhome/squidproject/squidpasswd line 23, <DATA> line 558.

That is due to the HTTPD-User-Manage packages missing from your system. If you are not using the htpasswd file authentication type for the script you can comment out these packages in the file.

    use HTTPD::Authen;
    use HTTPD::GroupAdmin;

If you are using the htpasswd and htgroup files for authentication you will [need the packages from cpan](http://search.cpan.org/~lds/HTTPD-User-Manage-1.66/).
