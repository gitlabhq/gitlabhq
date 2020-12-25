# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.ciConfig' do
  include GraphqlHelpers

  subject(:post_graphql_query) { post_graphql(query, current_user: user) }

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, creator: user, namespace: user.namespace) }

  let_it_be(:content) do
    File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci_includes.yml'))
  end

  let(:query) do
    %(
      query {
        ciConfig(projectPath: "#{project.full_path}", content: "#{content}") {
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

  it_behaves_like 'a working graphql query' do
    before do
      post_graphql_query
    end
  end

  it 'returns the correct structure' do
    post_graphql_query

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

  context 'when the config file includes other files' do
    let_it_be(:content) do
      YAML.dump(
        include: 'other_file.yml',
        rspec: {
          script: 'rspec'
        }
      )
    end

    before do
      allow_next_instance_of(Repository) do |repository|
        allow(repository).to receive(:blob_data_at).with(an_instance_of(String), 'other_file.yml') do
          YAML.dump(
            build: {
              script: 'build'
            }
          )
        end
      end

      post_graphql_query
    end

    it_behaves_like 'a working graphql query'

    it 'returns the correct structure with included files' do
      expect(graphql_data['ciConfig']).to eq(
        "status" => "VALID",
        "errors" => [],
        "stages" =>
        {
          "nodes" =>
          [
            {
              "name" => "test",
              "groups" =>
              {
                "nodes" =>
                [
                  {
                    "name" => "build",
                    "size" => 1,
                    "jobs" =>
                    {
                      "nodes" =>
                      [
                        { "name" => "build", "groupName" => "build", "stage" => "test", "needs" => { "nodes" => [] } }
                      ]
                    }
                  },
                  {
                    "name" => "rspec",
                    "size" => 1,
                    "jobs" =>
                    {
                      "nodes" =>
                      [
                        { "name" => "rspec", "groupName" => "rspec", "stage" => "test", "needs" => { "nodes" => [] } }
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
end
