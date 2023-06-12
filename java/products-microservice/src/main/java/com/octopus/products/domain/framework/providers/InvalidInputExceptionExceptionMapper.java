package com.octopus.products.domain.framework.providers;

import com.octopus.exceptions.InvalidInputException;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.Response.Status;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;
import lombok.NonNull;

/**
 * Converts a InvalidInputException exception to a HTTP response.
 */
@Provider
public class InvalidInputExceptionExceptionMapper implements ExceptionMapper<InvalidInputException> {

  @Override
  public Response toResponse(@NonNull final InvalidInputException exception) {
    return Response.status(Status.BAD_REQUEST.getStatusCode(), exception.toString()).build();
  }
}
