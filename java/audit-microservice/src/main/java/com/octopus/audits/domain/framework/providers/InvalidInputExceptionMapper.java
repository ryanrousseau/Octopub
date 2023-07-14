package com.octopus.audits.domain.framework.providers;

import com.octopus.audits.domain.exceptions.InvalidInput;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.core.Response.Status;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;
import lombok.NonNull;

/**
 * Converts a InvalidInput exception to a HTTP response.
 */
@Provider
public class InvalidInputExceptionMapper implements ExceptionMapper<InvalidInput> {

  @Override
  public Response toResponse(@NonNull final InvalidInput exception) {
    return Response.status(Status.BAD_REQUEST.getStatusCode(), exception.toString()).build();
  }
}
