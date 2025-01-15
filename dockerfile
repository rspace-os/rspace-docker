# THIS FILE IS FOR DEVELOPMENT USE ONLY. IT DOES NOT INCLUDE THE DATABASE. YOU MUST ONLY USE THIS FOR DEVELOPMENT OR IF YOU WISH TO BUILD YOUR OWN IMAGE. WE DO NOT PROVIDE SUPPORT FOR THE JENKINSFILE TEMPLATE AND IS PROVIDED AS-IS
# USE THE DOCKER-COMPOSE.YAML FILE FOR PRODUCTION USE.

FROM tomcat:9-jre17
LABEL COMPANY="ResearchSpace"
LABEL APPLICATION="RSpace Docker Development Build - NOT For Production / Pilot / Trial Use"
LABEL maintainer=”ramon@researchspace.com”

RUN mkdir /etc/rspace

ADD https://github.com/rspace-os/rspace-web/releases/download/2.5.0/researchspace-2.5.0.war /usr/local/tomcat/webapps/ROOT.war

COPY deployment.properties /etc/rspace/deployment.properties
COPY configs/rspace.env /usr/local/tomcat/bin/setenv.sh
COPY configs/tomcat-locate.sh /usr/libexec/tomcat9/tomcat-locate-java.sh
COPY configs/server.xml /usr/local/tomcat/conf/server.xml

RUN mkdir /media/rspace
RUN mkdir /media/rspace/archive
RUN mkdir /media/rspace/archives
RUN mkdir /media/rspace/backup
RUN mkdir /media/rspace/download
RUN mkdir /media/rspace/file_store
RUN mkdir /media/rspace/FTsearchIndices
RUN mkdir /media/rspace/indices
RUN mkdir /media/rspace/jmelody
RUN mkdir /media/rspace/logs-audit
RUN mkdir /media/rspace/LuceneFTsearchIndices
RUN mkdir /media/rspace/tomcat-tmp

VOLUME /media/rspace

EXPOSE 8080

CMD ["/usr/local/tomcat/bin/catalina.sh", "run"]
