package com.octopus.products.application.http;

import com.github.jasminb.jsonapi.exceptions.DocumentSerializationException;
import com.google.common.net.HttpHeaders;
import com.octopus.Constants;
import com.octopus.jsonapi.AcceptHeaderVerifier;
import com.octopus.products.application.Paths;
import com.octopus.products.domain.handlers.ResourceHandlerGetAll;
import java.util.List;
import jakarta.enterprise.context.RequestScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.HeaderParam;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

/**
 * WHen this app is run as a web server, this class defines the REST API endpoints.
 */
@Path(Paths.API_ENDPOINT)
@RequestScoped
public class JsonApiRootResourceGetAll {

  @Inject
  ResourceHandlerGetAll resourceHandler;

  @Inject
  AcceptHeaderVerifier acceptHeaderVerifier;

  /**
   * The resource collection endpoint.
   *
   * @param acceptHeader The "Accept" headers.
   * @param filter       The RSQL query string.
   * @return a HTTP response object.
   * @throws DocumentSerializationException Thrown if the entity could not be converted to a JSONAPI
   *                                        resource.
   */
  @GET
  @Produces({Constants.JsonApi.JSONAPI_CONTENT_TYPE, MediaType.APPLICATION_JSON})
  @Transactional
  public Response getAll(
      @HeaderParam(Constants.DATA_PARTITION_HEADER) final List<String> dataPartitionHeaders,
      @HeaderParam(HttpHeaders.ACCEPT) final List<String> acceptHeader,
      @HeaderParam(HttpHeaders.AUTHORIZATION) final String authorizationHeader,
      @HeaderParam(Constants.SERVICE_AUTHORIZATION_HEADER) final String serviceAuthorizationHeader,
      @QueryParam(Constants.JsonApi.FILTER_QUERY_PARAM) final String filter,
      @QueryParam(Constants.JsonApi.PAGE_OFFSET_QUERY_PARAM) final String pageOffset,
      @QueryParam(Constants.JsonApi.PAGE_LIMIT_QUERY_PARAM) final String pageLimit)
      throws DocumentSerializationException {
    acceptHeaderVerifier.checkAcceptHeader(acceptHeader);
    return Response.ok(resourceHandler.getAll(
            dataPartitionHeaders,
            filter,
            pageOffset,
            pageLimit,
            authorizationHeader,
            serviceAuthorizationHeader))
        .build();
  }
}
