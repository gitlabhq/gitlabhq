# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.ciConfig' do
  include GraphqlHelpers

  subject(:post_graphql_query) { post_graphql(query, current_user: user) }

  let(:user) { create(:user) }

  let_it_be(:content) do
    File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci_includes.yml'))
  end

  let(:query) do
    %(
      query {
        ciConfig(content: "#{content}") {
          status
          errors
          stages {
            name
            groups {
              name
              size
              jobs {
                name
                groupName
                stage
                needs {
                  name
                }
              }
            }
          }
        }
      }
    )
  end

  before do
    post_graphql_query
  end

  it_behaves_like 'a working graphql query'

  it 'returns the correct structure' do
    expect(graphql_data['ciConfig']).to eq(
      "status" => "VALID",
      "errors" => [],
      "stages" =>
      [
        {
          "name" => "build",
          "groups" =>
          [
            {
              "name" => "rspec",
              "size" => 2,
              "jobs" =>
              [
                { "name" => "rspec 0 1", "groupName" => "rspec", "stage" => "build", "needs" => [] },
                { "name" => "rspec 0 2", "groupName" => "rspec", "stage" => "build", "needs" => [] }
              ]
            },
            {
              "name" => "spinach", "size" => 1, "jobs" =>
              [
                { "name" => "spinach", "groupName" => "spinach", "stage" => "build", "needs" => [] }
              ]
            }
          ]
        },
        {
          "name" => "test",
          "groups" =>
          [
            {
              "name" => "docker",
              "size" => 1,
              "jobs" => [
                { "name" => "docker", "groupName" => "docker", "stage" => "test", "needs" => [{ "name" => "spinach" }, { "name" => "rspec 0 1" }] }
              ]
            }
          ]
        }
      ]
    )
  end
end
