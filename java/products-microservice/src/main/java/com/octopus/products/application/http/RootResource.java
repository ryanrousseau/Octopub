package com.octopus.products.application.http;

import com.octopus.Constants;
import jakarta.enterprise.context.RequestScoped;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

/** A resource to respond to health check requests. */
@Path("/")
@RequestScoped
public class RootResource {

  /**
   * Platforms like the AWS ALB Ingress controller expect services to respond on the root path
   * for health checks.
   *
   * @return a HTTP response object.
   */
  @GET
  @Produces({Constants.JsonApi.JSONAPI_CONTENT_TYPE, MediaType.APPLICATION_JSON})
  public Response healthCollectionGet()  {
    return Response.ok().build();
  }
}
