FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /src
COPY pom.xml .
RUN mvn -B -q dependency:go-offline
COPY src ./src
RUN mvn -B -q package -DskipTests

# Settings live in the jar (catalog-join.properties) and in the mounted overlay (CATALOG_CONFIG);
# JVM flags in JDK_JAVA_OPTIONS. Commands: run (default), create-topics, print-config, sim-*.
FROM eclipse-temurin:21-jre
ARG UID=10001
RUN useradd --system --uid ${UID} app && mkdir -p /var/lib/catalog-join && chown app /var/lib/catalog-join
COPY --from=build /src/target/catalog-join.jar /app/catalog-join.jar
USER ${UID}
ENV JDK_JAVA_OPTIONS="-XX:MaxRAMPercentage=40 -XX:+ExitOnOutOfMemoryError"
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/catalog-join.jar"]
CMD ["run"]
