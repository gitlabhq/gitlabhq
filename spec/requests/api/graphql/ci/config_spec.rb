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
            nodes {
              name
              groups {
                nodes {
                  name
                  size
                  jobs {
                    nodes {
                      name
                      groupName
                      stage
                      needs {
                        nodes {
                          name
                        }
                      }
                    }
                  }
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
      {
        "nodes" =>
        [
          {
            "name" => "build",
            "groups" =>
            {
              "nodes" =>
              [
                {
                  "name" => "rspec",
                  "size" => 2,
                  "jobs" =>
                  {
                    "nodes" =>
                    [
                      { "name" => "rspec 0 1", "groupName" => "rspec", "stage" => "build", "needs" => { "nodes" => [] } },
                      { "name" => "rspec 0 2", "groupName" => "rspec", "stage" => "build", "needs" => { "nodes" => [] } }
                    ]
                  }
                },
                {
                  "name" => "spinach", "size" => 1, "jobs" =>
                {
                  "nodes" =>
                    [
                      { "name" => "spinach", "groupName" => "spinach", "stage" => "build", "needs" => { "nodes" => [] } }
                    ]
                  }
                }
              ]
            }
          },
          {
            "name" => "test",
            "groups" =>
            {
              "nodes" =>
              [
                {
                  "name" => "docker",
                  "size" => 1,
                    "jobs" =>
                    {
                      "nodes" => [
                      { "name" => "docker", "groupName" => "docker", "stage" => "test", "needs" => { "nodes" => [{ "name" => "spinach" }, { "name" => "rspec 0 1" }] } }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
    )
  end
end
