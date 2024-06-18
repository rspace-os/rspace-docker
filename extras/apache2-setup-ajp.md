AJP

Setting up apache2 is a fairly straight forward task. 

You can run apache2 on your host or as another container.

You'll need to do the following.

- Edit the server.xml file in configs and uncomment out the AJP connector (line 100).
- Add the extra ports to the docker config file
- Get a SSL certificate
- Have a hostname to access apache over

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

        
        # If you're using AJP
        ProxyPass /.well-known !
        ProxyPass / ajp://rspace-app:8009/
        ProxyPassReverse / ajp://rspace-app:8009/


	SSLCertificateFile /file-path
	SSLCertificateKeyFile /file-path

</VirtualHost>
```
This is just an example config, please ensure you know what you are doing before you expose a server to the internet.

If you're having errors in RSpace, please try and replicate the error visiting RSpace on localhost:8080 before opening a GitHub issues ticket, this will help us know if the error is being caused by RSpace, or by your reverse proxy.
