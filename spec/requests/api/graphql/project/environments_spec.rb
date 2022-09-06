# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project Environments query' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :private, :repository) }
  let_it_be(:environment) { create(:environment, project: project) }
  let_it_be(:developer) { create(:user).tap { |u| project.add_developer(u) } }

  subject { post_graphql(query, current_user: user) }

  let(:user) { developer }

  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          environment(name: "#{environment.name}") {
            slug
            createdAt
            updatedAt
            autoStopAt
            autoDeleteAt
            tier
            environmentType
          }
        }
      }
    )
  end

  it 'returns the specified fields of the environment', :aggregate_failures do
    environment.update!(auto_stop_at: 1.day.ago, auto_delete_at: 2.days.ago, environment_type: 'review')

    subject

    environment_data = graphql_data.dig('project', 'environment')
    expect(environment_data['slug']).to eq(environment.slug)
    expect(environment_data['createdAt']).to eq(environment.created_at.iso8601)
    expect(environment_data['updatedAt']).to eq(environment.updated_at.iso8601)
    expect(environment_data['autoStopAt']).to eq(environment.auto_stop_at.iso8601)
    expect(environment_data['autoDeleteAt']).to eq(environment.auto_delete_at.iso8601)
    expect(environment_data['tier']).to eq(environment.tier.upcase)
    expect(environment_data['environmentType']).to eq(environment.environment_type)
  end
end
