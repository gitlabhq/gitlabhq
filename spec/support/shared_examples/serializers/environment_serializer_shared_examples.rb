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

  def serialize(grouping:)
    EnvironmentSerializer.new(current_user: user, project: project).yield_self do |serializer|
      serializer.within_folders if grouping
      serializer.represent(Environment.where(project: project))
    end
  end
end
