# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.ciConfig', feature_category: :continuous_integration do
  include GraphqlHelpers
  include StubRequests
  include RepoHelpers

  subject(:post_graphql_query) { post_graphql(query, current_user: user) }

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository, creator: user, namespace: user.namespace) }

  let_it_be(:content) do
    File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci_includes.yml'))
  end

  let(:query) do
    %(
      query {
        ciConfig(projectPath: "#{project.full_path}", content: "#{content}", dryRun: false) {
          status
          errors
          warnings
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
                      script
                      beforeScript
                      afterScript
                      allowFailure
                      only {
                        refs
                      }
                      when
                      except {
                        refs
                      }
                      environment
                      tags
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
          mergedYaml
          includes {
            type
            location
            blob
            raw
            extra
            contextProject
            contextSha
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

    expect(graphql_data['ciConfig']).to include(
      "status" => "VALID",
      "errors" => [],
      "warnings" => [],
      "includes" => [],
      "mergedYaml" => a_kind_of(String),
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
                      {
                        "name" => "rspec 0 1",
                        "groupName" => "rspec",
                        "stage" => "build",
                        "script" => ["rake spec"],
                        "beforeScript" => ["bundle install", "bundle exec rake db:create"],
                        "afterScript" => ["echo 'run this after'"],
                        "allowFailure" => false,
                        "only" => { "refs" => %w[branches master] },
                        "when" => "on_success",
                        "except" => nil,
                        "environment" => nil,
                        "tags" => %w[ruby postgres],
                        "needs" => { "nodes" => [] }
                      },
                      {
                        "name" => "rspec 0 2",
                        "groupName" => "rspec",
                        "stage" => "build",
                        "script" => ["rake spec"],
                        "beforeScript" => ["bundle install", "bundle exec rake db:create"],
                        "afterScript" => ["echo 'run this after'"],
                        "allowFailure" => true,
                        "only" => { "refs" => %w[branches tags] },
                        "when" => "on_failure",
                        "except" => nil,
                        "environment" => nil,
                        "tags" => [],
                        "needs" => { "nodes" => [] }
                      }
                    ]
                  }
                },
                {
                  "name" => "spinach", "size" => 1, "jobs" =>
                {
                  "nodes" =>
                    [
                      {
                        "name" => "spinach",
                        "groupName" => "spinach",
                        "stage" => "build",
                        "script" => ["rake spinach"],
                        "beforeScript" => ["bundle install", "bundle exec rake db:create"],
                        "afterScript" => ["echo 'run this after'"],
                        "allowFailure" => false,
                        "only" => { "refs" => %w[branches tags] },
                        "when" => "on_success",
                        "except" => { "refs" => ["tags"] },
                        "environment" => nil,
                        "tags" => [],
                        "needs" => { "nodes" => [] }
                      }
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
                        {
                          "name" => "docker",
                          "groupName" => "docker",
                          "stage" => "test",
                          "script" => ["curl http://dockerhub/URL"],
                          "beforeScript" => ["bundle install", "bundle exec rake db:create"],
                          "afterScript" => ["echo 'run this after'"],
                          "allowFailure" => true,
                          "only" => { "refs" => %w[branches tags] },
                          "when" => "manual",
                          "except" => { "refs" => ["branches"] },
                          "environment" => nil,
                          "tags" => [],
                          "needs" => { "nodes" => [{ "name" => "spinach" }, { "name" => "rspec 0 1" }] }
                        }
                      ]
                  }
                }
              ]
            }
          },
          {
            "name" => "deploy",
            "groups" =>
            {
              "nodes" =>
              [
                {
                  "name" => "deploy_job",
                  "size" => 1,
                  "jobs" =>
                    {
                      "nodes" => [
                        {
                          "name" => "deploy_job",
                          "groupName" => "deploy_job",
                          "stage" => "deploy",
                          "script" => ["echo 'done'"],
                          "beforeScript" => ["bundle install", "bundle exec rake db:create"],
                          "afterScript" => ["echo 'run this after'"],
                          "allowFailure" => false,
                          "only" => { "refs" => %w[branches tags] },
                          "when" => "on_success",
                          "except" => nil,
                          "environment" => "production",
                          "tags" => [],
                          "needs" => { "nodes" => [] }
                        }
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

    let(:project_files) do
      {
        'other_file.yml' => <<~YAML
        build:
          script: build
        YAML
      }
    end

    around do |example|
      create_and_delete_files(project, project_files) do
        example.run
      end
    end

    before do
      post_graphql_query
    end

    it_behaves_like 'a working graphql query'

    it 'returns the correct structure with included files' do
      expect(graphql_data['ciConfig']).to eq(
        "status" => "VALID",
        "errors" => [],
        "warnings" => [],
        "includes" => [
          {
            "type" => "local",
            "location" => "other_file.yml",
            "blob" => "http://localhost/#{project.full_path}/-/blob/#{project.commit.sha}/other_file.yml",
            "raw" => "http://localhost/#{project.full_path}/-/raw/#{project.commit.sha}/other_file.yml",
            "extra" => {},
            "contextProject" => project.full_path,
            "contextSha" => project.commit.sha
          }
        ],
        "mergedYaml" => "---\nbuild:\n  script: build\nrspec:\n  script: rspec\n",
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
                        {
                          "name" => "build",
                          "stage" => "test",
                          "groupName" => "build",
                          "script" => ["build"],
                          "afterScript" => [],
                          "beforeScript" => [],
                          "allowFailure" => false,
                          "environment" => nil,
                          "except" => nil,
                          "only" => { "refs" => %w[branches tags] },
                          "when" => "on_success",
                          "tags" => [],
                          "needs" => { "nodes" => [] }
                        }
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
                        { "name" => "rspec",
                          "stage" => "test",
                          "groupName" => "rspec",
                          "script" => ["rspec"],
                          "afterScript" => [],
                          "beforeScript" => [],
                          "allowFailure" => false,
                          "environment" => nil,
                          "except" => nil,
                          "only" => { "refs" => %w[branches tags] },
                          "when" => "on_success",
                          "tags" => [],
                          "needs" => { "nodes" => [] } }
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

  context 'when the config file has multiple includes' do
    let_it_be(:other_project) { create(:project, :repository, creator: user, namespace: user.namespace) }

    let_it_be(:content) do
      YAML.dump(
        include: [
          { local: 'other_file.yml' },
          { remote: 'https://gitlab.com/gitlab-org/gitlab/raw/1234/.hello.yml' },
          { file: 'other_project_file.yml', project: other_project.full_path },
          { template: 'Jobs/Build.gitlab-ci.yml' },
          { component: "gitlab.com/#{other_project.full_path}/my_component@#{other_project.default_branch}" }
        ],
        rspec: {
          script: 'rspec'
        }
      )
    end

    let(:remote_file_content) do
      YAML.dump(
        remote_file_test: {
          script: 'remote_file_test'
        }
      )
    end

    let(:project_files) do
      {
        'other_file.yml' => <<~YAML
        build:
          script: build
        YAML
      }
    end

    let(:other_project_files) do
      {
        'other_project_file.yml' => <<~YAML,
        other_project_test:
          script: other_project_test
        YAML
        'templates/my_component.yml' => "my-job:\n  script: echo"
      }
    end

    around do |example|
      create_and_delete_files(project, project_files) do
        create_and_delete_files(other_project, other_project_files) do
          example.run
        end
      end
    end

    before do
      stub_full_request('https://gitlab.com/gitlab-org/gitlab/raw/1234/.hello.yml').to_return(body: remote_file_content)

      settings = GitlabSettings::Options.build({ 'server_fqdn' => 'gitlab.com' })
      allow(::Settings).to receive(:gitlab_ci).and_return(settings)

      post_graphql_query
    end

    it_behaves_like 'a working graphql query'

    it 'returns correct includes' do
      expect(graphql_data['ciConfig']["includes"]).to eq(
        [
          {
            "type" => "local",
            "location" => "other_file.yml",
            "blob" => "http://localhost/#{project.full_path}/-/blob/#{project.commit.sha}/other_file.yml",
            "raw" => "http://localhost/#{project.full_path}/-/raw/#{project.commit.sha}/other_file.yml",
            "extra" => {},
            "contextProject" => project.full_path,
            "contextSha" => project.commit.sha
          },
          {
            "type" => "remote",
            "location" => "https://gitlab.com/gitlab-org/gitlab/raw/1234/.hello.yml",
            "blob" => nil,
            "raw" => "https://gitlab.com/gitlab-org/gitlab/raw/1234/.hello.yml",
            "extra" => {},
            "contextProject" => project.full_path,
            "contextSha" => project.commit.sha
          },
          {
            "type" => "file",
            "location" => "other_project_file.yml",
            "blob" => "http://localhost/#{other_project.full_path}/-/blob/#{other_project.commit.sha}/other_project_file.yml",
            "raw" => "http://localhost/#{other_project.full_path}/-/raw/#{other_project.commit.sha}/other_project_file.yml",
            "extra" => { "project" => other_project.full_path, "ref" => "HEAD" },
            "contextProject" => project.full_path,
            "contextSha" => project.commit.sha
          },
          {
            "type" => "template",
            "location" => "Jobs/Build.gitlab-ci.yml",
            "blob" => nil,
            "raw" => "https://gitlab.com/gitlab-org/gitlab/-/raw/master/lib/gitlab/ci/templates/Jobs/Build.gitlab-ci.yml",
            "extra" => {},
            "contextProject" => project.full_path,
            "contextSha" => project.commit.sha
          },
          {
            "type" => "component",
            "location" => "gitlab.com/#{other_project.full_path}/my_component@#{other_project.default_branch}",
            "blob" => "http://localhost/#{other_project.full_path}/-/blob/#{other_project.commit.sha}/templates/my_component.yml",
            "raw" => nil,
            "extra" => {},
            "contextProject" => project.full_path,
            "contextSha" => project.commit.sha
          }
        ]
      )
    end
  end

  describe 'skip_verify_project_sha' do
    let(:user) { project.owner }
    let(:sha) { project.commit.sha }
    let(:skip_verify_project_sha) { nil }
    let(:content) { YAML.dump(build: { script: 'echo' }) }
    let(:required_args) { { projectPath: project.full_path, content: content } }
    let(:optional_args) { { sha: sha, skip_verify_project_sha: skip_verify_project_sha }.compact }

    let(:query) do
      graphql_query_for(
        'ciConfig',
        required_args.merge(optional_args),
        %w[errors mergedYaml]
      )
    end

    before do
      post_graphql_query
    end

    shared_examples 'content is valid' do
      it 'returns the expected data without validation errors' do
        expect(graphql_data_at(:ciConfig)).to eq(
          'errors' => [],
          'mergedYaml' => "---\nbuild:\n  script: echo\n"
        )
      end
    end

    shared_examples 'returning error' do
      it 'returns an error' do
        expect(graphql_data_at(:ciConfig, :errors)).to include(
          /configuration originates from an external project or a commit not associated with a Git reference/)
      end
    end

    shared_examples 'when the sha exists in the main project' do
      context 'when skip_verify_project_sha is not provided' do
        let(:skip_verify_project_sha) { nil }

        it_behaves_like 'content is valid'
      end

      context 'when skip_verify_project_sha is false' do
        let(:skip_verify_project_sha) { false }

        it_behaves_like 'content is valid'
      end

      context 'when skip_verify_project_sha is true' do
        let(:skip_verify_project_sha) { true }

        it_behaves_like 'content is valid'
      end
    end

    context 'when the sha is from the main project' do
      it_behaves_like 'when the sha exists in the main project'
    end

    context 'when the sha is from a fork project' do
      include_context 'when a project repository contains a forked commit'

      let(:sha) { forked_commit_sha }

      context 'when the sha is associated with a main project ref' do
        before_all do
          repository.add_branch(project.owner, 'branch1', forked_commit_sha)
        end

        after(:all) do
          repository.rm_branch(project.owner, 'branch1')
        end

        it_behaves_like 'when the sha exists in the main project'
      end

      context 'when the sha is not associated with a main project ref' do
        context 'when skip_verify_project_sha is not provided' do
          let(:skip_verify_project_sha) { nil }

          it_behaves_like 'returning error'
        end

        context 'when skip_verify_project_sha is false' do
          let(:skip_verify_project_sha) { false }

          it_behaves_like 'returning error'
        end

        context 'when skip_verify_project_sha is true' do
          let(:skip_verify_project_sha) { true }

          it_behaves_like 'content is valid'
        end
      end
    end

    context 'when the sha is invalid' do
      let(:sha) { 'invalid-sha' }

      it_behaves_like 'when the sha exists in the main project'
    end
  end
end
