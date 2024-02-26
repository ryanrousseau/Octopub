package com.octopus.audits.infrastructure.repositories;

import com.github.tennaito.rsql.jpa.JpaPredicateVisitor;
import com.github.tennaito.rsql.misc.EntityManagerAdapter;
import com.octopus.Constants;
import com.octopus.audits.domain.entities.Audit;
import com.octopus.audits.domain.exceptions.InvalidInput;
import com.octopus.audits.domain.wrappers.FilteredResultWrapper;
import cz.jirutka.rsql.parser.RSQLParser;
import cz.jirutka.rsql.parser.ast.Node;
import cz.jirutka.rsql.parser.ast.RSQLVisitor;
import io.vavr.control.Try;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.persistence.EntityManager;
import jakarta.persistence.Tuple;
import jakarta.persistence.TypedQuery;
import jakarta.persistence.criteria.CriteriaQuery;
import jakarta.persistence.criteria.Predicate;
import jakarta.persistence.criteria.Root;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validator;
import lombok.NonNull;
import org.apache.commons.codec.binary.Base64;
import org.apache.commons.lang3.math.NumberUtils;
import org.h2.util.StringUtils;
import org.hibernate.query.criteria.HibernateCriteriaBuilder;
import org.hibernate.query.criteria.JpaCriteriaQuery;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Repositories are the interface between the application and the data store. They don't contain any
 * business logic, security rules, or manual audit logging.
 */
@ApplicationScoped
public class AuditRepository {

  @Inject
  EntityManager em;

  @Inject
  Validator validator;

  /**
   * Get a single entity.
   *
   * @param id The ID of the entity to update.
   * @return The entity.
   */
  public Audit findOne(final int id) {
    final Audit audit = em.find(Audit.class, id);
    /*
     We don't expect any local code to modify the entity returned here. Any changes will be done by
     returning the entity to a client, the client makes the appropriate updates, and the updated
     entity is sent back with a new request.

     To prevent the entity from being accidentally updated, we detach it from the context.
     */
    if (audit != null) {
      em.detach(audit);
    }
    return audit;
  }

  /**
   * Returns all matching entities.
   *
   * @param partitions The partitions that entities can be found in.
   * @param filter     The RSQL filter used to query the entities.
   * @return The matching entities.
   */
  public FilteredResultWrapper<Audit> findAll(
      @NonNull final List<String> partitions,
      final String filter,
      final String pageOffset,
      final String pageLimit) {

    // Counting records is proving to be a PITA in Hibernate 6. If there is an exception, return -1.
    final Long count = Try.of(() -> countResults(createQuery(partitions, filter, Tuple.class)))
        .getOrElse(-1L);

    // Deal with paging
    final CriteriaQuery<Audit> queryRoot = createQuery(partitions, filter, Audit.class);
    final TypedQuery<Audit> query = em.createQuery(queryRoot);
    final int pageLimitParsed = NumberUtils.toInt(pageLimit, Constants.DEFAULT_PAGE_LIMIT);
    final int pageOffsetParsed = NumberUtils.toInt(pageOffset, Constants.DEFAULT_PAGE_OFFSET);
    query.setFirstResult(pageOffsetParsed);
    query.setMaxResults(pageLimitParsed);
    final List<Audit> results = query.getResultList();

    // detach all the entities
    em.clear();

    return new FilteredResultWrapper(results, count);
  }

  /**
   * See <a href="https://hibernate.atlassian.net/browse/HHH-17410">HHH-17410</a> and
   * <a href="https://github.com/hibernate/hibernate-orm/blob/main/hibernate-core/src/test/java/org/hibernate/orm/test/query/criteria/CountQueryTests.java">this test</a>.
   *
   * @param query The query whose results you wish to count
   * @return The number of results
   */
  private Long countResults(final JpaCriteriaQuery<Tuple> query) {
    return em.createQuery(query.createCountQuery()).getSingleResult();
  }

  private <T> JpaCriteriaQuery<T> createQuery(@NonNull final List<String> partitions,
                                           final String filter,
                                           Class<T> clazz) {
    final HibernateCriteriaBuilder builder = (HibernateCriteriaBuilder) em.getCriteriaBuilder();

    final JpaCriteriaQuery<T> criteria = builder.createQuery(clazz);
    final Root<Audit> root = criteria.from(Audit.class);
    criteria.orderBy(builder.desc(root.get("id")));

    // add the partition search rules
    final Predicate partitionPredicate =
        builder.or(
            partitions.stream()
                .filter(org.apache.commons.lang3.StringUtils::isNotBlank)
                .map(p -> builder.equal(root.get("dataPartition"), p))
                .collect(Collectors.toList())
                .toArray(new Predicate[0]));

    if (!StringUtils.isNullOrEmpty(filter)) {
      /*
        Makes use of RSQL queries to filter any responses:
        https://github.com/TriloBitSystems/rsql-jpa
      */
      final EntityManagerAdapter adapter = new EntityManagerAdapter(em);
      final RSQLVisitor<Predicate, EntityManagerAdapter> visitor =
              new JpaPredicateVisitor<Audit>().defineRoot(root);
      final Node rootNode = new RSQLParser().parse(filter);
      final Predicate filterPredicate = rootNode.accept(visitor, adapter);

      // combine with the filter rules
      final Predicate combinedPredicate = builder.and(partitionPredicate, filterPredicate);

      criteria.where(combinedPredicate);
    } else {
      criteria.where(partitionPredicate);
    }

    return criteria;
  }

  /**
   * Saves a new audit in the data store.
   *
   * @param audit The audit to save.
   * @return The newly created entity.
   */
  public Audit save(@NonNull final Audit audit) {
    audit.id = null;

    validateEntity(audit);

    em.persist(audit);
    em.flush();
    return audit;
  }

  private void validateEntity(final Audit audit) {
    /*
      A sanity check to ensure that any audit record that indicates it has encrypted values
      has encoded those values as Base64. Note that this doesn't verify that the values are actually
      encrypted, but simply serves as a safeguard to ensure clients creating encrypted entries
      haven't forgotten to process the (supposedly) encrypted values.
    */
    if (audit.encryptedSubject && !Base64.isBase64(audit.subject)) {
      throw new InvalidInput("Encrypted values must be encoded as Base64");
    }

    if (audit.encryptedObject && !Base64.isBase64(audit.object)) {
      throw new InvalidInput("Encrypted values must be encoded as Base64");
    }

    final Set<ConstraintViolation<Audit>> violations = validator.validate(audit);
    if (violations.isEmpty()) {
      return;
    }

    throw new InvalidInput(
        violations.stream().map(cv -> cv.getMessage()).collect(Collectors.joining(", ")));
  }
}
