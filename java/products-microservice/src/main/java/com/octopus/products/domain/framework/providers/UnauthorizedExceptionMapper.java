package com.octopus.products.domain.framework.providers;

import com.octopus.exceptions.UnauthorizedException;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.Response.Status;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;
import lombok.NonNull;

/**
 * Converts a EntityNotFoundException exception to a HTTP response.
 */
@Provider
public class UnauthorizedExceptionMapper implements ExceptionMapper<UnauthorizedException> {

  @Override
  public Response toResponse(@NonNull final UnauthorizedException exception) {
    return Response.status(Status.UNAUTHORIZED.getStatusCode(), "You do not have permission to perform this action")
        .build();
  }
}
