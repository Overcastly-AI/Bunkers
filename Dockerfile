FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /src
COPY pom.xml .
RUN mvn -B -q dependency:go-offline
COPY src ./src
RUN mvn -B -q package -DskipTests

# Settings live in the jar (catalog-join.properties) and in the mounted overlay (CATALOG_CONFIG);
# JVM flags in JDK_JAVA_OPTIONS. bin/catalog-join attaches the Datadog agent when dd.trace.enabled.
# Commands: run (default), create-topics, print-config, sim-generate, sim-verify.
FROM eclipse-temurin:21-jre
ARG UID=10001
RUN useradd --system --uid ${UID} app && mkdir -p /var/lib/catalog-join && chown app /var/lib/catalog-join
COPY --from=build /src/target/catalog-join.jar /src/target/dd-java-agent.jar /app/
COPY bin/catalog-join /app/bin/catalog-join
USER ${UID}
ENV JDK_JAVA_OPTIONS="-XX:MaxRAMPercentage=40 -XX:+ExitOnOutOfMemoryError"
EXPOSE 8080
ENTRYPOINT ["/app/bin/catalog-join"]
CMD ["run"]
