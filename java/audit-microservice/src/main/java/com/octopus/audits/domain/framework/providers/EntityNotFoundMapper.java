package com.octopus.audits.domain.framework.providers;

import com.octopus.audits.domain.exceptions.EntityNotFound;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.Response.Status;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;
import lombok.NonNull;

/**
 * Converts a EntityNotFound exception to a HTTP response.
 */
@Provider
public class EntityNotFoundMapper implements ExceptionMapper<EntityNotFound> {

  @Override
  public Response toResponse(@NonNull final EntityNotFound exception) {
    return Response.status(Status.NOT_FOUND.getStatusCode(), "The request resource was not found")
        .build();
  }
}
