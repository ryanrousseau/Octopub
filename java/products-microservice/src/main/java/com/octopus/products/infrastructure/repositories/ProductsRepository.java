package com.octopus.products.infrastructure.repositories;

import com.github.tennaito.rsql.jpa.JpaPredicateVisitor;
import com.github.tennaito.rsql.misc.EntityManagerAdapter;
import com.octopus.Constants;
import com.octopus.products.domain.entities.Product;
import com.octopus.exceptions.InvalidInputException;
import com.octopus.wrappers.FilteredResultWrapper;
import cz.jirutka.rsql.parser.RSQLParser;
import cz.jirutka.rsql.parser.ast.Node;
import cz.jirutka.rsql.parser.ast.RSQLVisitor;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

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
import org.apache.commons.lang3.math.NumberUtils;
import org.h2.util.StringUtils;
import org.hibernate.query.criteria.HibernateCriteriaBuilder;
import org.hibernate.query.criteria.JpaCriteriaQuery;
import org.hibernate.query.sqm.tree.SqmCopyContext;
import org.hibernate.query.sqm.tree.select.SqmQuerySpec;
import org.hibernate.query.sqm.tree.select.SqmSelectStatement;
import org.hibernate.query.sqm.tree.select.SqmSubQuery;

/**
 * Repositories are the interface between the application and the data store. They don't contain any
 * business logic, security rules, or manual audit logging.
 */
@ApplicationScoped
public class ProductsRepository {

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
  public Product findOne(final int id) {
    final Product product = em.find(Product.class, id);
    /*
     We don't expect any local code to modify the entity returned here. Any changes will be done by
     returning the entity to a client, the client makes the appropriate updates, and the updated
     entity is sent back with a new request.

     To prevent the entity from being accidentally updated, we detach it from the context.
     */
    if (product != null) {
      em.detach(product);
    }
    return product;
  }

  /**
   * Returns all matching entities.
   *
   * @param partitions The partitions that entities can be found in.
   * @param filter     The RSQL filter used to query the entities.
   * @return The matching entities.
   */
  public FilteredResultWrapper<Product> findAll(
      @NonNull final List<String> partitions,
      final String filter,
      final String pageOffset,
      final String pageLimit) {

    // Counting records is proving to be a PITA in Hibernate 6. If there is an exception, return -1.
    final Long count = Try.of(() -> countResults(createQuery(partitions, filter, Tuple.class)))
        .getOrElse(-1L);

    // Deal with paging
    final CriteriaQuery<Product> queryRoot = createQuery(partitions, filter, Product.class);
    final TypedQuery<Product> query = em.createQuery(queryRoot);
    final int pageLimitParsed = NumberUtils.toInt(pageLimit, Constants.DEFAULT_PAGE_LIMIT);
    final int pageOffsetParsed = NumberUtils.toInt(pageOffset, Constants.DEFAULT_PAGE_OFFSET);
    query.setFirstResult(pageOffsetParsed);
    query.setMaxResults(pageLimitParsed);
    final List<Product> results = query.getResultList();

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
    final Root<Product> root = criteria.from(Product.class);
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
          new JpaPredicateVisitor<Product>().defineRoot(root);
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
   * Saves a new resource in the data store.
   *
   * @param product The resource to save.
   * @return The newly created entity.
   */
  public Product save(@NonNull final Product product) {
    product.setId(null);

    validateEntity(product);

    em.persist(product);
    em.flush();
    return product;
  }

  private void validateEntity(final Product product) {
    final Set<ConstraintViolation<Product>> violations = validator.validate(product);
    if (violations.isEmpty()) {
      return;
    }

    throw new InvalidInputException(
        violations.stream().map(cv -> cv.getMessage()).collect(Collectors.joining(", ")));
  }
}
