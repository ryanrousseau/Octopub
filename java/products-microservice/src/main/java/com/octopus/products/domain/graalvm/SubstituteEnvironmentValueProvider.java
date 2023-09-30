package com.octopus.products.domain.graalvm;

import com.oracle.svm.core.annotate.Delete;
import com.oracle.svm.core.annotate.Substitute;
import com.oracle.svm.core.annotate.TargetClass;

import java.util.Map;

/**
 * Reimplements the fix from <a href="https://github.com/quarkusio/quarkus/pull/25960">this PR</a>.
 * See <a href="https://github.com/quarkusio/quarkus/issues/33030">this issue</a>.
 */
@TargetClass(className = "liquibase.configuration.core.EnvironmentValueProvider")
final class SubstituteEnvironmentValueProvider {

  @Delete
  private Map<String, String> environment;

  @Substitute
  protected Map<?, ?> getMap() {
    return System.getenv();
  }

}