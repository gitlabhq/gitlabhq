# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Preloaders::Environments::DeploymentPreloader do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :repository) }

  let_it_be(:environment_a) { create(:environment, project: project, state: :available) }
  let_it_be(:environment_b) { create(:environment, project: project, state: :available) }

  let_it_be(:pipeline) { create(:ci_pipeline, user: user, project: project, sha: project.commit.sha) }
  let_it_be(:ci_build_a) { create(:ci_build, user: user, project: project, pipeline: pipeline, environment: environment_a.name) }
  let_it_be(:ci_build_b) { create(:ci_build, user: user, project: project, pipeline: pipeline, environment: environment_a.name) }
  let_it_be(:ci_build_c) { create(:ci_build, user: user, project: project, pipeline: pipeline, environment: environment_b.name) }

  before do
    create(:deployment, :success, project: project, environment: environment_a, deployable: ci_build_a)
    create(:deployment, :success, project: project, environment: environment_a, deployable: ci_build_b)
    create(:deployment, :success, project: project, environment: environment_b, deployable: ci_build_c)
  end

  def preload_association(association_name)
    described_class.new(project.environments)
      .execute_with_union(association_name, deployment_associations)
  end

  def deployment_associations
    {
      user: [],
      deployable: {
        pipeline: {
          manual_actions: []
        }
      }
    }
  end

  it 'does not trigger N+1 queries' do
    control = ActiveRecord::QueryRecorder.new { preload_association(:last_deployment) }

    ci_build_d = create(:ci_build, user: user, project: project, pipeline: pipeline)
    create(:deployment, :success, project: project, environment: environment_b, deployable: ci_build_d)

    expect { preload_association(:last_deployment) }.not_to exceed_query_limit(control)
  end

  it 'batch loads the dependent associations' do
    preload_association(:last_deployment)

    expect do
      project.environments.first.last_deployment.deployable.pipeline.manual_actions
    end.not_to exceed_query_limit(0)
  end

  # Example query scoped with IN clause for `last_deployment` association preload:
  # SELECT DISTINCT ON (environment_id) deployments.* FROM "deployments" WHERE "deployments"."status" IN (1, 2, 3, 4, 6) AND "deployments"."environment_id" IN (35, 34, 33) ORDER BY environment_id, deployments.id DESC
  it 'avoids scoping with IN clause during preload' do
    control = ActiveRecord::QueryRecorder.new { preload_association(:last_deployment) }

    default_preload_query = control.occurrences_by_line_method.first[1][:occurrences].any? { |i| i.include?('"deployments"."environment_id" IN') }

    expect(default_preload_query).to be(false)
  end

  it 'sets environment on the associated deployment', :aggregate_failures do
    preload_association(:last_deployment)

    expect do
      project.environments.each { |environment| environment.last_deployment.environment }
    end.not_to exceed_query_limit(0)

    project.environments.each do |environment|
      expect(environment.last_deployment.environment).to eq(environment)
    end
  end

  it 'does not attempt to set environment on a nil deployment' do
    create(:environment, project: project, state: :available)

    expect { preload_association(:last_deployment) }.not_to raise_error
  end
end
