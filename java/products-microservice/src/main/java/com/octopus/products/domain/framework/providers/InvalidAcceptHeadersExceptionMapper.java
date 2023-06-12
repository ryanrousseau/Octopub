package com.octopus.products.domain.framework.providers;

import com.octopus.exceptions.InvalidAcceptHeadersException;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.Response.Status;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;
import lombok.NonNull;

/**
 * Converts a InvalidAcceptHeadersException exception to a HTTP response.
 */
@Provider
public class InvalidAcceptHeadersExceptionMapper implements ExceptionMapper<InvalidAcceptHeadersException> {

  @Override
  public Response toResponse(@NonNull final InvalidAcceptHeadersException exception) {
    return Response.status(Status.NOT_ACCEPTABLE.getStatusCode()).build();
  }
}
