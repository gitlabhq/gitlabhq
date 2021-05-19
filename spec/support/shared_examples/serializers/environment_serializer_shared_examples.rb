# frozen_string_literal: true
RSpec.shared_examples 'avoid N+1 on environments serialization' do
  it 'avoids N+1 database queries with grouping', :request_store do
    create_environment_with_associations(project)

    control = ActiveRecord::QueryRecorder.new { serialize(grouping: true) }

    create_environment_with_associations(project)

    expect { serialize(grouping: true) }.not_to exceed_query_limit(control.count)
  end

  it 'avoids N+1 database queries without grouping', :request_store do
    create_environment_with_associations(project)

    control = ActiveRecord::QueryRecorder.new { serialize(grouping: false) }

    create_environment_with_associations(project)

    expect { serialize(grouping: false) }.not_to exceed_query_limit(control.count)
  end

  it 'does not preload for environments that does not exist in the page', :request_store do
    create_environment_with_associations(project)

    first_page_query = ActiveRecord::QueryRecorder.new do
      serialize(grouping: false, query: { page: 1, per_page: 1 } )
    end

    second_page_query = ActiveRecord::QueryRecorder.new do
      serialize(grouping: false, query: { page: 2, per_page: 1 } )
    end

    expect(second_page_query.count).to be < first_page_query.count
  end

  def serialize(grouping:, query: nil)
    query ||= { page: 1, per_page: 1 }
    request = double(url: "#{Gitlab.config.gitlab.url}:8080/api/v4/projects?#{query.to_query}", query_parameters: query)

    EnvironmentSerializer.new(current_user: user, project: project).yield_self do |serializer|
      serializer.within_folders if grouping
      serializer.with_pagination(request, spy('response'))
      serializer.represent(Environment.where(project: project))
    end
  end
end
