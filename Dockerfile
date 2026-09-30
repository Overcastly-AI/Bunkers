FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /src
COPY pom.xml .
RUN mvn -B -q dependency:go-offline
COPY src ./src
RUN mvn -B -q package -DskipTests

FROM eclipse-temurin:21-jre
RUN useradd --system --uid 10001 app && mkdir -p /var/lib/catalog-join && chown app /var/lib/catalog-join
COPY --from=build /src/target/catalog-join.jar /app/catalog-join.jar
COPY deploy/application.properties /etc/catalog-join/application.properties
USER app
ENV CATALOG_CONFIG=/etc/catalog-join/application.properties
EXPOSE 8080
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=50", "-jar", "/app/catalog-join.jar"]
