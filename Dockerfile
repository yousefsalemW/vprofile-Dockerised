# ---------- Build stage ----------
FROM maven:3.9.9-eclipse-temurin-8 AS builder
WORKDIR /build

# Resolve dependencies in a separate layer so they stay cached
# when only application source code changes.
COPY . . 
RUN mvn -B clean package 

# ---------- Runtime stage ----------
# JRE base image instead of JDK: no compiler, no jmap/jstack,
# smaller image and reduced attack surface.
FROM tomcat:9-jre8-temurin

# Create a dedicated non-root system user with no login shell.
RUN groupadd -r appgroup && useradd -r -g appgroup -s /sbin/nologin appuser

# Remove Tomcat's default apps (manager, host-manager, examples, docs).
RUN rm -rf /usr/local/tomcat/webapps/*

# Deploy the application as ROOT.war, owned by the runtime user.
COPY --from=builder --chown=appuser:appgroup \
     /build/target/vprofile-v2.war /usr/local/tomcat/webapps/ROOT.war

# Grant write access ONLY to the directories Tomcat actually needs at runtime.
# conf/, bin/ and lib/ stay root-owned, so a compromised app cannot
# rewrite server.xml or drop a malicious JAR into the classpath.
RUN chown -R appuser:appgroup \
      /usr/local/tomcat/webapps \
      /usr/local/tomcat/work \
      /usr/local/tomcat/temp \
      /usr/local/tomcat/logs

USER appuser
EXPOSE 8080
CMD ["catalina.sh", "run"]
