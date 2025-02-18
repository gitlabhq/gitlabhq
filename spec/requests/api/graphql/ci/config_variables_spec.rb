# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).ciConfigVariables(ref)', feature_category: :ci_variables do
  include GraphqlHelpers
  include ReactiveCachingHelpers

  let_it_be(:content) do
    File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
  end

  let_it_be(:project) { create(:project, :custom_repo, :public, files: { '.gitlab-ci.yml' => content }) }
  let_it_be(:user) { create(:user) }

  let(:service) { Ci::ListConfigVariablesService.new(project, user) }
  let(:ref) { project.default_branch }

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          ciConfigVariables(ref: "#{ref}") {
            key
            value
            valueOptions
            description
          }
        }
      }
    )
  end

  context 'when the user has the correct permissions' do
    before do
      project.add_maintainer(user)
      allow(Ci::ListConfigVariablesService)
        .to receive(:new)
        .and_return(service)
    end

    context 'when the cache is not empty' do
      before do
        synchronous_reactive_cache(service)
      end

      it 'returns the CI variables for the config' do
        expect(service)
          .to receive(:execute)
          .with(ref)
          .and_call_original

        post_graphql(query, current_user: user)

        expect(graphql_data.dig('project', 'ciConfigVariables')).to contain_exactly(
          {
            'key' => 'KEY_VALUE_VAR',
            'value' => 'value x',
            'valueOptions' => nil,
            'description' => 'value of KEY_VALUE_VAR'
          },
          {
            'key' => 'DB_NAME',
            'value' => 'postgres',
            'valueOptions' => nil,
            'description' => nil
          },
          {
            'key' => 'ENVIRONMENT_VAR',
            'value' => 'env var value',
            'valueOptions' => ['env var value', 'env var value2'],
            'description' => 'env var description'
          }
        )
      end
    end

    context 'when the cache is empty' do
      it 'returns nothing' do
        post_graphql(query, current_user: user)

        expect(graphql_data.dig('project', 'ciConfigVariables')).to be_nil
      end
    end
  end

  context 'when the user is not authorized' do
    before do
      project.add_guest(user)
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
