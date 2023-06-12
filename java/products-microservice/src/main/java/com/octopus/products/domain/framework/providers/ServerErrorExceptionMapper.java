package com.octopus.products.domain.framework.providers;

import jakarta.ws.rs.ServerErrorException;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.Response.Status;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;
import lombok.NonNull;

/**
 * Converts a EntityNotFoundException exception to a HTTP response.
 */
@Provider
public class ServerErrorExceptionMapper implements ExceptionMapper<ServerErrorException> {

  @Override
  public Response toResponse(@NonNull final ServerErrorException exception) {
    return Response.status(Status.INTERNAL_SERVER_ERROR.getStatusCode(), "A server error was encountered.")
        .build();
  }
}
