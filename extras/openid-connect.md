# OpenID Connect SSO for RSpace on Docker

**This requires RSpace 2.4.0 or higher to work** 

These steps are used to setup RSpace with a OpenID Connect compatible SSO system. You must have already setup RSpace before starting this work

You should still keep the current folder and file structure of your existing rspace-docker container set. We will be expanding on the work already done to get RSpace to run on Docker that you can follow along on this repos main readme file

This process mainly provides the introduction of a new "rspace-web-sso" container and the removal of ports being directly exposed on the "rspace-app" container - Instead they are now proxied through the sso container and only ports 80 and 443 are exposed.

**You must have valid and trusted SSL certificates for the configuration to work**

Firstly, we'll start with the new container. Add this snipped of code into your docker-compose.yaml file:

```

    rspace-web-sso:
      container_name: rspace-web-sso
      tty: true
      environment:
          - TZ=BST
      ports:
          - 80:80
          - 443:443
      image: ubuntu/apache2:2.4-22.04_beta
      volumes:
        - type: bind
          source: ./configs/apache2.conf
          target: /etc/apache2/sites-enabled/rspace-sso.conf
        - type: bind
          source: ./certs/cert.pem
          target: /etc/apache2/ssl/cert.pem
        - type: bind
          source: ./certs/chain.crt
          target: /etc/apache2/ssl/chain.crt
        - type: bind
          source: ./certs/priv.key
          target: /etc/apache2/ssl/priv.key
        - type: bind
          source: ./configs/apache.setup
          target: /etc/apache2/setup.sh
      command: bash /etc/apache2/setup.sh


```

We also need to create a new folder called "certs", this is where you'll place your private key, chain file and certificate file. You can use a Let's Encrypt certificate or a paid SSL certificate. It doesn't really matter, it just needs to be from a trusted source and follow the correct format of a chain file, cert file and private key file.

You can also remove the port 8080 entry from the rspace-web container after creating the rspace-web-sso container in your docker-compose.yaml file

Your apache2.conf file is your main config file. There is an example apache2 config file at the end of this doc just make sure that you change the proxy pass to the following (to match the RSpace container) and change all hostnames and IdP setup info.

You also need to make sure that AJP is available in your server.xml file, you just need to uncomment it (around line 100 of the server.xml file on rspace-docker github). 
You can also comment the http connector on port 8080 since we won't be using that and that port is no longer exposed by docker.

In your apache2.conf file, you will set up your IdP details. You can find more information on IdP details here - https://github.com/OpenIDC/mod_auth_openidc

You will also need to add the following SSO values in your RSpace deployment.properties file:
```
deployment.standalone=false
deployment.sso.type=openid
user.signup=true
```

There is also a apache.setup file at the bottom of this guide. As the rspace-web-sso container does not keep a persistent state, setup happens each time the container is started up. This script performs the setup process. At the end of the file, it tails /dev/null - This is because without this the container will automatically stop after startup, but this tail keeps it alive.

The timezone also needs to be set correctly, to ensure session timers are correct.

## RSpace claims <---> OpenID Claims
In order for RSpace to correctly understand what OpenID claims match with email, username, firstName and lastName, we need to match the OpenID claims to RSpace claims.

The OpenID Claims used vary depending on which IdP you use. You will need to know the names of the claims your IdP is sending to RSpace. You can see a standard list here - https://docs.vindicia.com/bundle/b_ConnectProductDescription/page/topics/OIDCStandardClaimsAndScopes_c.html

Once you know the claim names sent from the IdP, you can map them to the correct RSpace claims. Below is a list of the claims you need to match between RSpace and the IdP

```
#### The claim for the RSpace username
deployment.sso.openid.usernameClaim=

#### Any additional claims for the RSpace username
deployment.sso.openid.additionalUsernameClaim=

#### The claim for the email address
deployment.sso.openid.emailClaim=

#### The claim for the firstname
deployment.sso.openid.firstNameClaim=

#### The claim for the lastname
deployment.sso.openid.lastNameClaim=
```

For example, if I want my RSpace username to be the email claim passed on from the IdP, then I would set: _deployment.sso.openid.usernameClaim=OIDC_CLAIM_email_

Remember that claims must follow the format: OIDC_CLAIM_$ClaimName

You should notice that the claims are correctly passed to RSpace, and if you try to visit RSpace, you should see the RSpace sign up page with the sign up form pre-filled with the claims passed from the IdP.

## Logout Setup

Logout is setup on the RSpace side, in the RSpace deployment.properties, your logout URL should always point to

```
deployment.sso.logout.url=/openidAuthRedirect?logout=%2Fpublic%2Fssologout
```

This should be the openid auth endpoint specified in apache + ?logout. This endpoint kills the apache openid session. There is also a redirect to /public/ssologout - This is the logout page that is shown to the user. It is essential that it points to this page as urls under /public/ are not protected by SSO, and therefore, you will not be re-authenticated / logged in again.

If your provider does not support single sign out, then you will be shown a message that states "You have logged out of RSpace, but are still logged into your SSO provider. Please logout of your SSO provider" . If you navigate back to the /workspace, then you will be re-logged in. This is because you have logged out of RSpace, but your SSO account is still logged in with your IdP (Okta, Microsoft, etc..)

If your provider does support single sign out, then you can configure the addition property

```
deployment.sso.idp.logout.url=https://dev-07217600.okta.com/login/signout
```

This property changes the message on the logout page to add a hyperlink with the option "You have logged out of RSpace, but are still logged into your SSO provider. Please click here to logout of your SSO provider"

_You can find the idp logout url by going to the openid metadata url, and then finding the logout url._

**Remember: Everytime you make a change to the RSpace deployment.properties file, RSpace needs to be restarted for the changes to take effect.**

## Troubleshooting commands

**View the apache2 error log**
docker exec -it rspace-web-sso cat /var/log/apache2/error.log

## Example files
### apache2.conf file
```
<VirtualHost *:443>
        ServerName YOURSERVERNAME.EXAMPLE.ORG
        
        ProxyRequests Off
        Header always set Strict-Transport-Security "max-age=600;"
        Header edit Set-Cookie ^(.*)$ $1;SameSite=None
        SSLEngine on
        SSLCertificateFile YOUR-CERT-PATH
        SSLCertificateKeyFile YOUR-KEY-PATH
        SSLCertificateChainFile YOUR-CHAIN-PATH

   
        RemoteIPHeader X-Forwarded-For
        ProxyPass / ajp://rspace-app:8009/
        ProxyPassReverse / ajp://rspace-app:8009/




        OIDCProviderMetadataURL <URL HERE>
        OIDCClientID <CLIENT ID HERE>
        OIDCClientSecret <SECRET ID HERE>

        OIDCRedirectURI /openidAuthRedirect

        # This is for encryption of the cookie https://github.com/OpenIDC/mod_auth_openidc/blob/master/auth_openidc.conf#L16
        # use randomly generated password
        OIDCCryptoPassphrase <ENTER RANDOM PASSWORD>

        # lifetime of apache openid session, in seconds (use 0 for idp default)
        OIDCSessionInactivityTimeout 120
        OIDCSessionMaxDuration 0
        #logout url
        OIDCProviderEndSessionEndpoint https://SERVER-URL.COM/public/ssologout


        # This is the endpoint for auth, so make sure this matches the OIDCRedirectURI above.
        <Location /openidAuthRedirect>
           AuthType openid-connect
           Require valid-user
        </Location>

        # Protects every location apart from the ones below with SSO
        <LocationMatch "(?i)^(?!/(monitoring|public|styles|ssoinfo|scripts|resources|wopi|api|logout|images))">
           AuthType openid-connect
           Require valid-user
        </LocationMatch>

</VirtualHost>
```

### apache.setup file
```
apt update
apt install libapache2-mod-auth-openidc ca-certificates openssl -y
update-ca-certificates
a2enmod ssl headers auth_openidc rewrite proxy proxy_ajp remoteip
service apache2 restart
tail -f /dev/null
```
