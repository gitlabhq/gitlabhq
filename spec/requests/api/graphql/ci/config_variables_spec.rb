# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).ciConfigVariables(sha)' do
  include GraphqlHelpers
  include ReactiveCachingHelpers

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:user) { create(:user) }
  let_it_be(:content) do
    File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
  end

  let(:sha) { project.commit.sha }

  let(:service) { Ci::ListConfigVariablesService.new(project, user) }

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          ciConfigVariables(sha: "#{sha}") {
            key
            value
            description
          }
        }
      }
    )
  end

  context 'when the user has the correct permissions' do
    before do
      project.add_maintainer(user)
      stub_ci_pipeline_yaml_file(content)
      allow(Ci::ListConfigVariablesService)
        .to receive(:new)
        .and_return(service)
    end

    context 'when the cache is not empty' do
      before do
        synchronous_reactive_cache(service)
      end

      it 'returns the CI variables for the config' do
        post_graphql(query, current_user: user)

        expect(graphql_data.dig('project', 'ciConfigVariables')).to contain_exactly(
          {
            'key' => 'DB_NAME',
            'value' => 'postgres',
            'description' => nil
          },
          {
            'key' => 'ENVIRONMENT_VAR',
            'value' => 'env var value',
            'description' => 'env var description'
          }
        )
      end
    end

    context 'when the cache is empty' do
      let(:sha) { 'main' }

      it 'returns nothing' do
        post_graphql(query, current_user: user)

        expect(graphql_data.dig('project', 'ciConfigVariables')).to be_nil
      end
    end
  end

  context 'when the user is not authorized' do
    before do
      project.add_guest(user)
      stub_ci_pipeline_yaml_file(content)
      allow(Ci::ListConfigVariablesService)
        .to receive(:new)
        .and_return(service)
      synchronous_reactive_cache(service)
    end

    it 'returns nothing' do
      post_graphql(query, current_user: user)

      expect(graphql_data.dig('project', 'ciConfigVariables')).to be_nil
    end
  end
end
