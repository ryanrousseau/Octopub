package com.octopus.audits.domain.handlers;

import com.github.jasminb.jsonapi.JSONAPIDocument;
import com.github.jasminb.jsonapi.ResourceConverter;
import com.github.jasminb.jsonapi.exceptions.DocumentSerializationException;
import com.octopus.audits.domain.Constants;
import com.octopus.audits.domain.entities.Health;
import com.octopus.audits.infrastructure.repositories.AuditRepository;

import java.util.List;

import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import lombok.NonNull;
import org.eclipse.microprofile.config.inject.ConfigProperty;

/**
 * Handles the health check requests.
 */
@ApplicationScoped
public class HealthHandler {

  @Inject
  ResourceConverter resourceConverter;

  @Inject
  AuditRepository auditRepository;

  @ConfigProperty(name = "app.version")
  String appVersion;

  /**
   * Returns a response when the root health endpoint has been accessed.
   *
   * @return HTTP OK with the app version
   * @throws DocumentSerializationException If the response can not be converted to JSONAPI
   */
  public String getHealth()
      throws DocumentSerializationException {

    // Query for an empty set of results. This validates a connection to the database.
    auditRepository.findAll(List.of(Constants.DEFAULT_PARTITION), null, "0", "0");

    return respondWithHealth(
        Health.builder()
            .status("OK")
            .version(appVersion)
            .build());
  }

  /**
   * Get the health check response content.
   *
   * @param path   The path that was checked.
   * @param method The method that was checked.
   * @return The JSONAPI response representing the health check.
   * @throws DocumentSerializationException Thrown if the entity could not be converted to a JSONAPI
   *                                        resource.
   */
  public String getHealth(@NonNull final String path, @NonNull final String method)
      throws DocumentSerializationException {

    // Query for an empty set of results. This validates a connection to the database.
    auditRepository.findAll(List.of(Constants.DEFAULT_PARTITION), null, "0", "0");

    return respondWithHealth(
        Health.builder()
            .status("OK")
            .path(path)
            .method(method)
            .endpoint(path + "/" + method)
            .version(appVersion)
            .build());
  }

  private String respondWithHealth(final Health health)
      throws DocumentSerializationException {
    final JSONAPIDocument<Health> document = new JSONAPIDocument<>(health);
    return new String(resourceConverter.writeDocument(document));
  }
}
