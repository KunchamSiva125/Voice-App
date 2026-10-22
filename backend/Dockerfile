# Stage 1: Build the Spring Boot application using Maven and Java 21
FROM maven:3.9.8-eclipse-temurin-21 AS build
WORKDIR /app

# Copy pom.xml and pre-fetch dependencies for fast builds
COPY pom.xml .
RUN mvn dependency:go-offline -B || true

# Copy source code and build jar
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Lightweight Java 21 Runtime Image
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app

# Copy compiled jar from build stage
COPY --from=build /app/target/tiffin-ledger-backend-1.0.0.jar app.jar

# Render assigns port dynamically via $PORT
ENV PORT=8080
EXPOSE 8080

# JVM memory configuration optimized for Render free tier (512MB RAM)
ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-XX:+UseSerialGC", "-jar", "app.jar"]
