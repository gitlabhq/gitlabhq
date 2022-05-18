# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::EnvironmentsController do
  let_it_be(:project) { create(:project, :repository) }

  let(:environment) { create(:environment, name: 'production', project: project) }

  describe 'GET #show' do
    subject { get project_environment_path(project, environment) }

    before do
      sign_in(project.owner)
    end

    it 'avoids N+1 queries', :use_sql_query_cache do
      create_deployment_with_associations(commit_depth: 19)

      control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        get project_environment_path(project, environment), params: environment_params
      end

      18.downto(0).each { |n| create_deployment_with_associations(commit_depth: n) }

      # N+1s exist for loading commit emails and users
      expect do
        get project_environment_path(project, environment), params: environment_params
      end.not_to exceed_all_query_limit(control).with_threshold(9)
    end
  end

  def environment_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace,
                       project_id: project,
                       id: environment.id)
  end

  def create_deployment_with_associations(commit_depth:)
    commit = project.commit("HEAD~#{commit_depth}")
    create(:user, email: commit.author_email) unless User.find_by(email: commit.author_email)

    deployer = create(:user)
    pipeline = create(:ci_pipeline, project: environment.project)
    build = create(:ci_build, environment: environment.name, pipeline: pipeline, user: deployer)
    create(:deployment, :success, environment: environment, deployable: build, user: deployer,
           project: project, sha: commit.sha)
  end
end
