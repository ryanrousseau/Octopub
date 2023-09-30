package com.octopus.audits.domain.graalvm;

import com.oracle.svm.core.annotate.Delete;
import com.oracle.svm.core.annotate.Substitute;
import com.oracle.svm.core.annotate.TargetClass;

import java.util.Map;

/**
 * Reimplements the fix from https://github.com/quarkusio/quarkus/pull/25960
 * See https://github.com/quarkusio/quarkus/issues/33030
 */
@TargetClass(className = "liquibase.configuration.pro.EnvironmentValueProvider")
final class SubstituteEnvironmentValueProvider {

  @Delete
  private Map<String, String> environment;

  @Substitute
  protected Map<?, ?> getMap() {
    return System.getenv();
  }

}