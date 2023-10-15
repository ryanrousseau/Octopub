package com.octopus.products.application.gcf;

import com.google.cloud.functions.HttpFunction;
import com.google.cloud.functions.HttpRequest;
import com.google.cloud.functions.HttpResponse;
import com.google.common.net.HttpHeaders;
import com.octopus.Constants;
import com.octopus.jsonapi.AcceptHeaderVerifier;
import com.octopus.products.application.Paths;
import com.octopus.products.domain.handlers.HealthHandler;
import com.octopus.products.domain.handlers.ResourceHandlerCreate;
import com.octopus.products.domain.handlers.ResourceHandlerGetAll;
import com.octopus.products.domain.handlers.ResourceHandlerGetOne;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import org.apache.commons.io.IOUtils;

import java.io.Writer;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.List;
import java.util.regex.Matcher;

/**
 * GoogleCloudFunction is the entry point to this service when deployed as a Google Cloud Function.
 */
@ApplicationScoped
public class GoogleCloudFunction implements HttpFunction {

  @Inject
  ResourceHandlerGetAll resourceHandlerGetAll;

  @Inject
  ResourceHandlerGetOne resourceHandlerGetOne;

  @Inject
  ResourceHandlerCreate resourceHandlerCreate;

  @Inject
  AcceptHeaderVerifier acceptHeaderVerifier;

  @Inject
  HealthHandler healthHandler;

  @Override
  @Transactional
  public void service(final HttpRequest httpRequest, final HttpResponse httpResponse) throws Exception {
    acceptHeaderVerifier.checkAcceptHeader(getHeaderList(httpRequest, HttpHeaders.ACCEPT));

    if ("GET".equalsIgnoreCase(httpRequest.getMethod())) {
      serviceGet(httpRequest, httpResponse);
    }

    if ("POST".equalsIgnoreCase(httpRequest.getMethod())) {
      servicePost(httpRequest, httpResponse);
    }
  }

  private void servicePost(final HttpRequest httpRequest, final HttpResponse httpResponse) throws Exception {
    final Writer writer = httpResponse.getWriter();

    if (Paths.API_ENDPOINT.equals(httpRequest.getPath())) {
      final String body = IOUtils.toString(httpRequest.getInputStream(), StandardCharsets.UTF_8);

      final String response = resourceHandlerCreate.create(
          body,
          getHeaderList(httpRequest, Constants.DATA_PARTITION_HEADER),
          getHeader(httpRequest, HttpHeaders.AUTHORIZATION),
          getHeader(httpRequest, Constants.SERVICE_AUTHORIZATION_HEADER));
      writer.write(response);
      httpResponse.setStatusCode(201);
      httpResponse.setContentType(Constants.JsonApi.JSONAPI_CONTENT_TYPE);
      return;
    }

    httpResponse.setStatusCode(404);
  }

  private void serviceGet(final HttpRequest httpRequest, final HttpResponse httpResponse) throws Exception {
    final Writer writer = httpResponse.getWriter();

    if (Paths.HEALTH_ENDPOINT.equals(httpRequest.getPath()) || "/".equals(httpRequest.getPath())) {
      writer.write(healthHandler.getHealth());
      httpResponse.setStatusCode(200);
      httpResponse.setContentType(Constants.JsonApi.JSONAPI_CONTENT_TYPE);
      return;
    }

    if ((Paths.HEALTH_ENDPOINT + "/GET").equalsIgnoreCase(httpRequest.getPath())) {
      writer.write(healthHandler.getHealth(Paths.HEALTH_ENDPOINT, "GET"));
      httpResponse.setStatusCode(200);
      httpResponse.setContentType(Constants.JsonApi.JSONAPI_CONTENT_TYPE);
      return;
    }

    if (Paths.API_ENDPOINT.equals(httpRequest.getPath())) {
      writer.write(resourceHandlerGetAll.getAll(
          getHeaderList(httpRequest, Constants.DATA_PARTITION_HEADER),
          getHeader(httpRequest, Constants.JsonApi.FILTER_QUERY_PARAM),
          getHeader(httpRequest, Constants.JsonApi.PAGE_OFFSET_QUERY_PARAM),
          getHeader(httpRequest, Constants.JsonApi.PAGE_LIMIT_QUERY_PARAM),
          getHeader(httpRequest, HttpHeaders.AUTHORIZATION),
          getHeader(httpRequest, Constants.SERVICE_AUTHORIZATION_HEADER)));
      httpResponse.setStatusCode(200);
      httpResponse.setContentType(Constants.JsonApi.JSONAPI_CONTENT_TYPE);
      return;
    }

    final Matcher individualMatcher = Paths.API_ENDPOINT_INDIVIDUAL.matcher(httpRequest.getPath());
    if (individualMatcher.matches()) {
      writer.write(resourceHandlerGetOne.getOne(
          individualMatcher.group("id"),
          getHeaderList(httpRequest, Constants.DATA_PARTITION_HEADER),
          getHeader(httpRequest, HttpHeaders.AUTHORIZATION),
          getHeader(httpRequest, Constants.SERVICE_AUTHORIZATION_HEADER)));
      httpResponse.setStatusCode(200);
      httpResponse.setContentType(Constants.JsonApi.JSONAPI_CONTENT_TYPE);
      return;
    }


    final Matcher individualHealthMatcher = Paths.HEALTH_ENDPOINT_INDIVIDUAL.matcher(httpRequest.getPath());
    if (individualHealthMatcher.matches()) {
      final String method = individualHealthMatcher.group("method").toUpperCase();

      if ("POST".equals(method) || "GET".equals(method)) {
        writer.write(healthHandler.getHealth(Paths.HEALTH_ENDPOINT
            + individualHealthMatcher.group("id"), method.toUpperCase()));
        httpResponse.setStatusCode(200);
        httpResponse.setContentType(Constants.JsonApi.JSONAPI_CONTENT_TYPE);
        return;
      }
    }

    httpResponse.setStatusCode(404);
  }

  private List<String> getHeaderList(final HttpRequest httpRequest, final String header) {
    return httpRequest.getHeaders().getOrDefault(header, Collections.emptyList());
  }

  private String getHeader(final HttpRequest httpRequest, final String header) {
    return httpRequest.getHeaders().getOrDefault(header, Collections.emptyList())
        .stream()
        .findFirst()
        .orElse(null);
  }
}