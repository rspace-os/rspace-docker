HTTP/2

This method is more complicated to setup compared to AJP proxying due to the certificates involved.  

You can run apache2 on your host or as another container.

You'll need to do the following.

- Edit the server.xml file in configs and uncomment out the HTTP/2 connector (line 88).
- Add the extra ports to the docker config file
- Get a SSL certificate from a trusted CA
- Have a hostname to access apache over


When using HTTP/2, you will need to enter the certificate in the server XML file, in addition to the certificate in apache2. This has to be the same certificate and be from a trusted CA (self signed certs don't work.)

If you're getting keychain errors, please ensure your certificate setup is correct.

You will need to enable the following modules on apache: ssl, proxy, mod_ip.

Here is an example apache config, use this as a starting point:


```
<VirtualHost *:443>
	ServerName domain.example.com
	Protocols h2 http/1.1
	ProxyRequests Off
	ProxyPreserveHost On
	Header always set Strict-Transport-Security "max-age=600;"
	Header edit Set-Cookie ^(.*)$ $1;SameSite=None
	# If you're using HTTP/2
	SSLProxyEngine on
	RemoteIPHeader X-Forwarded-For
	ProxyPass / h2://rspace-app:8443/
	ProxyPassReverse / https://rspace-app:8443/
	SSLCertificateFile /file-path
	SSLCertificateKeyFile /file-path
</VirtualHost>
```

This is just an example config, please ensure you know what you are doing before you expose a server to the internet.

If you're having errors in RSpace, please try and replicate the error visiting RSpace on localhost:8080 before opening a GitHub issues ticket, this will help us know if the error is being caused by RSpace, or by your reverse proxy.
