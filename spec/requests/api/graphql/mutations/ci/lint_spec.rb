# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ciLint', feature_category: :pipeline_composition do
  include GraphqlHelpers
  include StubRequests
  include RepoHelpers

  let_it_be(:project) { create(:project, :repository, create_tag: '1.0.0') }
  let_it_be(:user) { project.creator }

  let_it_be(:content) do
    File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci_includes.yml'))
  end

  let(:dry_run) { false }
  let(:ref) { nil }

  let(:mutation) do
    graphql_mutation(:ci_lint, { project_path: project.full_path, content: content, ref: ref, dry_run: dry_run }) do
      <<~FIELDS
      errors
      config {
        errors
        includes {
          type
          location
          raw
          blob
          extra
          contextProject
          contextSha
        }
        mergedYaml
        status
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
      }
      FIELDS
    end
  end

  subject(:post_mutation) do
    post_graphql_mutation(mutation, current_user: user)
  end

  context 'when ci_lint_mutation is disabled' do
    before do
      stub_feature_flags(ci_lint_mutation: false)
    end

    it 'does not lint the config' do
      expect(::Gitlab::Ci::Lint).not_to receive(:new)

      post_mutation

      expect(graphql_mutation_response(:ci_lint)['config']).to be_nil
      expect(graphql_mutation_response(:ci_lint)['errors'].first).to include(
        'This mutation is unfinished and not yet available for use'
      )
    end
  end

  it_behaves_like 'a working graphql query' do
    before do
      post_mutation
    end
  end

  it 'returns the correct structure' do
    post_mutation

    expect(graphql_mutation_response(:ci_lint)['config']).to include(
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
      post_mutation
    end

    it_behaves_like 'a working graphql query'

    it 'returns the correct structure with included files' do
      expect(graphql_mutation_response(:ci_lint)['config']).to eq(
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

      post_mutation
    end

    it_behaves_like 'a working graphql query'

    it 'returns correct includes' do
      expect(graphql_mutation_response(:ci_lint)['config']['includes']).to eq(
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

  context 'when the `ref` argument is given' do
    let(:dry_run) { true }
    let(:ref) { '1.0.0' }

    it 'lints the config for that ref' do
      post_mutation

      response_config = graphql_mutation_response(:ci_lint)['config']
      response_job_names = response_config.dig('stages', 'nodes')
        .flat_map { |stage| stage.dig('groups', 'nodes') }
        .flat_map { |group| group.dig('jobs', 'nodes') }
        .pluck('name')

      # The spinach job does not run for tags, so it makes a good test that the ref is being properly applied.
      expect(response_job_names).not_to include('spinach')
    end
  end

  context 'when a Gitaly error is raised' do
    it 'tracks the exception' do
      expect(Gitlab::ErrorTracking).to receive(:track_and_raise_exception)
        .with(an_instance_of(GRPC::InvalidArgument), ref: project.default_branch)

      allow(Gitlab::Ci::Lint).to receive(:new).and_raise(GRPC::InvalidArgument)

      post_mutation
    end
  end
end
