FROM maven:3.9.6-amazoncorretto-21 AS MAVEN_TOOL_CHAIN

#RUN yum install -y wget tar gunzip

ARG GITHUB_TOKEN_VALUE
ENV GITHUB_TOKEN $GITHUB_TOKEN_VALUE

COPY . /tmp/fincloud/
WORKDIR /tmp/fincloud/
RUN mvn -B dependency:go-offline && mvn -B package

FROM amazoncorretto:21
ENV LANG C.UTF-8
RUN yum update -y && yum install -y wget openssl
#Yum no longer includes dumb-init ?
RUN wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.5/dumb-init_1.2.5_x86_64 \
    && chmod +x /usr/local/bin/dumb-init

# REST API Connectivity
EXPOSE 8888

RUN mkdir -p /app
RUN mkdir -p /config-server
COPY --from=MAVEN_TOOL_CHAIN '/tmp/fincloud/target/config-server.jar' /app/

ENTRYPOINT ["/usr/local/bin/dumb-init", "--"]
CMD ["java","-Dspring.profiles.active=native", "-Dlog4j2.formatMsgNoLookups=true","-Djava.security.egd=file:/dev/./urandom","-jar", "/app/config-server.jar"]

# HEALTHCHECK --interval=1m --timeout=3s CMD wget --quiet --tries=1 --spider http://localhost:8080/actuator/health || exit 1