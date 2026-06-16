# frozen_string_literal: true

RSpec.shared_examples 'avoid N+1 on environments serialization' do
  before do
    # Certificate-based clusters are a deprecated, ops-gated feature that
    # defaults to disabled in production. When enabled (the default in tests),
    # `Environment#deployment_platform` issues a per-environment cluster lookup
    # that the serializer does not (and need not) batch, making this N+1 check
    # order-dependent. Pin the flag to its production default so the test
    # measures the real code path. See:
    # https://gitlab.com/gitlab-org/gitlab/-/issues/353410
    stub_feature_flags(certificate_based_clusters: false)
  end

  it 'avoids N+1 database queries with grouping' do
    create_list_of_environments_with_associations(2)
    control = measure_serialization(grouping: true)

    create_list_of_environments_with_associations(2)

    expect { measure_serialization(grouping: true) }.not_to exceed_query_limit(control)
  end

  it 'avoids N+1 database queries without grouping' do
    create_list_of_environments_with_associations(2)
    control = measure_serialization(grouping: false)

    create_list_of_environments_with_associations(2)

    expect { measure_serialization(grouping: false) }.not_to exceed_query_limit(control)
  end

  it 'does not preload for environments that does not exist in the page', :request_store do
    create_environment_with_associations(project)

    first_page_query = ActiveRecord::QueryRecorder.new do
      serialize(grouping: false, query: { page: 1, per_page: 1 })
    end

    second_page_query = ActiveRecord::QueryRecorder.new do
      serialize(grouping: false, query: { page: 2, per_page: 1 })
    end

    expect(second_page_query.count).to be < first_page_query.count
  end

  def create_list_of_environments_with_associations(count)
    count.times { create_environment_with_associations(project) }
  end

  # Measures a single serialization from a cold cache so the comparison reflects
  # the queries the serializer actually issues, not state warmed by a previous
  # run. Each call:
  #
  # * resets the project's in-memory association cache (`project.reset`);
  # * runs inside its own request store. The example must therefore NOT be tagged
  #   `:request_store`: with no outer store active, `ensure_request_store` opens a
  #   fresh one and tears it down (and clears it) afterwards, isolating the
  #   control and experiment runs. Sharing a store would let the experiment reuse
  #   the control's batch-loaded rows (the deployment preloader memoizes
  #   `last_finished_deployment_group` via BatchLoader, which lives for the
  #   store's lifetime) and report an artificially low delta that masks real N+1s.
  #
  # The control already has multiple environments so the deployment preloader
  # batches its associations with `IN (...)` queries; adding more environments
  # then exercises the same batched query shapes. Starting from a single
  # environment would instead compare single-row (`= id`) control queries against
  # batched experiment queries, and that shape change alone inflates the delta
  # without any real N+1. With matching shapes the assertion reflects true
  # per-environment query growth and needs no threshold.
  def measure_serialization(grouping:)
    project.reset

    ActiveRecord::QueryRecorder.new do
      Gitlab::SafeRequestStore.ensure_request_store { serialize(grouping: grouping) }
    end
  end

  def serialize(grouping:, query: nil)
    query ||= { page: 1, per_page: 20 }
    request = double(url: "#{Gitlab.config.gitlab.url}:8080/api/v4/projects?#{query.to_query}", query_parameters: query)

    EnvironmentSerializer.new(current_user: user, project: project).then do |serializer|
      serializer.within_folders if grouping
      serializer.with_pagination(request, spy('response'))
      serializer.represent(Environment.where(project: project))
    end
  end
end
