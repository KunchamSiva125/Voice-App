package com.tiffin.ledger.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

@Service
public class KeepAliveService {

    private static final Logger log = LoggerFactory.getLogger(KeepAliveService.class);

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    @Value("${app.keep-alive.url:https://voice-app-0cys.onrender.com/api/health}")
    private String keepAliveUrl;

    @Value("${app.keep-alive.enabled:true}")
    private boolean keepAliveEnabled;

    /**
     * Pings the public health check endpoint every 10 minutes to prevent Render from sleeping.
     * Render spins down free-tier instances after 15 minutes of inbound inactivity.
     * Making an outbound HTTPS call to the public Render domain enters through Render's router,
     * resetting the 15-minute inactivity timer.
     */
    @Scheduled(initialDelay = 120000, fixedRate = 600000)
    public void pingSelf() {
        if (!keepAliveEnabled || keepAliveUrl == null || keepAliveUrl.trim().isEmpty()) {
            return;
        }

        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(keepAliveUrl))
                    .timeout(Duration.ofSeconds(15))
                    .header("User-Agent", "TiffinLedger-KeepAlive/1.0")
                    .GET()
                    .build();

            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            log.info("Keep-alive heartbeat sent to {}: status {}", keepAliveUrl, response.statusCode());
        } catch (Exception e) {
            log.warn("Keep-alive ping to {} failed: {}", keepAliveUrl, e.getMessage());
        }
    }
}
