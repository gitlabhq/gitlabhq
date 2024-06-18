# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config, feature_category: :pipeline_composition do
  include StubRequests
  include RepoHelpers

  let_it_be(:user) { create(:user) }

  before do
    allow_next_instance_of(Gitlab::Ci::Config::External::Context) do |instance|
      allow(instance).to receive(:check_execution_time!)
    end
  end

  let(:config) do
    described_class.new(yml, project: nil, pipeline: nil, sha: nil, user: nil)
  end

  context 'when config is valid' do
    let(:yml) do
      <<-EOS
        image: image:1.0

        rspec:
          script:
            - gem install rspec
            - rspec
      EOS
    end

    describe '#to_hash' do
      it 'returns hash created from string' do
        hash = {
          image: 'image:1.0',
          rspec: {
            script: ['gem install rspec',
                     'rspec']
          }
        }

        expect(config.to_hash).to eq hash
      end

      context 'when yml has stages' do
        let(:yml) do
          <<-EOS
            image: image:1.0
            stages:
              - custom_stage
            rspec:
              script:
                - gem install rspec
                - rspec
          EOS
        end

        specify do
          expect(config.to_hash[:stages]).to eq(['.pre', 'custom_stage', '.post'])
        end

        context 'with inject_edge_stages option disabled' do
          let(:config) do
            described_class.new(yml, project: nil, pipeline: nil, sha: nil, user: nil, inject_edge_stages: false)
          end

          specify do
            expect(config.to_hash[:stages]).to contain_exactly('custom_stage')
          end
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(config).to be_valid
        end

        it 'has no errors' do
          expect(config.errors).to be_empty
        end
      end
    end

    describe '#stages' do
      subject(:subject) { config.stages }

      context 'with default stages' do
        let(:default_stages) do
          %w[.pre build test deploy .post]
        end

        it { is_expected.to eq default_stages }
      end

      context 'with custom stages' do
        let(:yml) do
          <<-EOS
            stages:
              - stage1
              - stage2
            job1:
              stage: stage1
              script:
                - ls
          EOS
        end

        it { is_expected.to eq %w[.pre stage1 stage2 .post] }
      end
    end

    context 'when pipeline ref is provided' do
      let_it_be(:project) { create(:project, :repository) }
      let(:ref) { 'master' }

      let(:yml) do
        <<-EOS
          rspec:
            script: exit 0
        EOS
      end

      it 'sets the ref in the pipeline' do
        expect(Ci::Pipeline).to receive(:new).with(hash_including(ref: ref)).and_call_original

        described_class.new(yml, project: project, ref: ref, user: user)
      end
    end
  end

  describe '#included_templates' do
    let(:yml) do
      <<-EOS
        include:
          - template: Jobs/Deploy.gitlab-ci.yml
          - template: Jobs/Build.gitlab-ci.yml
          - remote: https://example.com/gitlab-ci.yml
      EOS
    end

    before do
      stub_request(:get, 'https://example.com/gitlab-ci.yml').to_return(status: 200, body: <<-EOS)
        test:
          script: [ 'echo hello world' ]
      EOS
    end

    subject(:included_templates) do
      config.included_templates
    end

    it { is_expected.to contain_exactly('Jobs/Deploy.gitlab-ci.yml', 'Jobs/Build.gitlab-ci.yml') }

    it 'stores includes' do
      expect(config.metadata[:includes]).to contain_exactly(
        { type: :template,
          location: 'Jobs/Deploy.gitlab-ci.yml',
          blob: nil,
          raw: 'https://gitlab.com/gitlab-org/gitlab/-/raw/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml',
          extra: {},
          context_project: nil,
          context_sha: nil },
        { type: :template,
          location: 'Jobs/Build.gitlab-ci.yml',
          blob: nil,
          raw: 'https://gitlab.com/gitlab-org/gitlab/-/raw/master/lib/gitlab/ci/templates/Jobs/Build.gitlab-ci.yml',
          extra: {},
          context_project: nil,
          context_sha: nil },
        { type: :remote,
          location: 'https://example.com/gitlab-ci.yml',
          blob: nil,
          raw: 'https://example.com/gitlab-ci.yml',
          extra: {},
          context_project: nil,
          context_sha: nil }
      )
    end
  end

  describe '#included_components' do
    let_it_be(:project1) { create(:project, :catalog_resource_with_components, create_tag: '1.0.0') }
    let_it_be(:project2) { create(:project, :catalog_resource_with_components, create_tag: '1.0.0') }

    let(:config) { described_class.new(yml, project: project1, user: user) }
    let(:server_fqdn) { 'acme.com' }

    let(:yml) do
      <<-EOS
        include:
          - component: #{server_fqdn}/#{project1.full_path}/dast@1.0.0
          - component: #{server_fqdn}/#{project2.full_path}/template@1.0.0
          - local: templates/secret-detection.yml
            inputs:
              website: test.com
      EOS
    end

    subject(:included_components) { config.included_components }

    before do
      project1.add_developer(user)
      project2.add_developer(user)

      settings = GitlabSettings::Options.build({ 'server_fqdn' => server_fqdn })
      allow(::Settings).to receive(:gitlab_ci).and_return(settings)
    end

    it 'returns only components included with `include:component`' do
      expect(config.metadata[:includes].size).to eq(3)
      expect(included_components).to contain_exactly(
        { project: project1, sha: project1.commit.sha, name: 'dast' },
        { project: project2, sha: project2.commit.sha, name: 'template' }
      )
    end

    context 'when duplicate components are included' do
      let(:yml) do
        <<-EOS
          include:
            - component: #{server_fqdn}/#{project1.full_path}/dast@1.0.0
            - component: #{server_fqdn}/#{project1.full_path}/dast@1.0.0
        EOS
      end

      it 'returns only unique components' do
        expect(config.metadata[:includes].size).to eq(2)
        expect(included_components).to contain_exactly(
          { project: project1, sha: project1.commit.sha, name: 'dast' }
        )
      end
    end
  end

  context 'when using extendable hash' do
    let(:yml) do
      <<-EOS
        image: image:1.0

        rspec:
          script: rspec

        test:
          extends: rspec
          image: ruby:alpine
      EOS
    end

    it 'correctly extends the hash' do
      hash = {
        image: 'image:1.0',
        rspec: { script: 'rspec' },
        test: {
          extends: 'rspec',
          image: 'ruby:alpine',
          script: 'rspec'
        }
      }

      expect(config).to be_valid
      expect(config.to_hash).to eq hash
    end
  end

  context 'when config is invalid' do
    context 'when yml is incorrect' do
      let(:yml) { '// invalid' }

      describe '.new' do
        it 'raises error' do
          expect { config }.to raise_error(
            described_class::ConfigError,
            /Invalid configuration format/
          )
        end
      end
    end

    context 'when yml is too big' do
      let(:yml) do
        <<~YAML
          --- &1
          - hi
          - *1
        YAML
      end

      describe '.new' do
        it 'raises error' do
          expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

          expect { config }.to raise_error(
            described_class::ConfigError,
            /The parsed YAML is too big/
          )
        end
      end
    end

    context 'when config logic is incorrect' do
      let(:yml) { 'before_script: "ls"' }

      describe '#valid?' do
        it 'is not valid' do
          expect(config).not_to be_valid
        end

        it 'has errors' do
          expect(config.errors).not_to be_empty
        end
      end

      describe '#errors' do
        it 'returns an array of strings' do
          expect(config.errors).to all(be_an_instance_of(String))
        end
      end
    end

    context 'when invalid extended hash has been provided' do
      let(:yml) do
        <<-EOS
          test:
            extends: test
            script: rspec
        EOS
      end

      it 'raises an error' do
        expect { config }.to raise_error(
          described_class::ConfigError, /circular dependency detected/
        )
      end
    end

    context 'when ports have been set' do
      context 'in the main image' do
        let(:yml) do
          <<-EOS
            image:
              name: image:1.0
              ports:
                - 80
          EOS
        end

        it 'raises an error' do
          expect(config.errors).to include("image config contains disallowed keys: ports")
        end
      end

      context 'in the job image' do
        let(:yml) do
          <<-EOS
            image: image:1.0

            test:
              script: rspec
              image:
                name: image:1.0
                ports:
                  - 80
          EOS
        end

        it 'raises an error' do
          expect(config.errors).to include("jobs:test:image config contains disallowed keys: ports")
        end
      end

      context 'in the services' do
        let(:yml) do
          <<-EOS
            image: image:1.0

            test:
              script: rspec
              image: image:1.0
              services:
                - name: test
                  alias: test
                  ports:
                    - 80
          EOS
        end

        it 'raises an error' do
          expect(config.errors).to include("jobs:test:services:service config contains disallowed keys: ports")
        end
      end
    end

    context 'when yaml uses circular !reference' do
      let(:yml) do
        <<~YAML
        job-1:
          script:
            - !reference [job-2, before_script]

        job-2:
          before_script: !reference [job-1, script]
        YAML
      end

      it 'raises error' do
        expect { config }.to raise_error(
          described_class::ConfigError,
          /!reference \["job-2", "before_script"\] is part of a circular chain/
        )
      end
    end
  end

  context "when using 'include' directive" do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :repository, group: group) }
    let_it_be(:main_project) { create(:project, :repository, :public, group: group) }

    let(:project_sha) { project.commit.id }
    let(:main_project_sha) { main_project.commit.id }

    let(:pipeline) { build(:ci_pipeline, project: project) }

    let(:remote_location) { 'https://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.gitlab-ci-1.yml' }
    let(:local_location) { 'spec/fixtures/gitlab/ci/external_files/.gitlab-ci-template-1.yml' }

    let(:local_file_content) do
      File.read(Rails.root.join(local_location))
    end

    let(:local_location_hash) do
      YAML.safe_load(local_file_content).deep_symbolize_keys
    end

    let(:remote_file_content) do
      <<~HEREDOC
      variables:
        POSTGRES_USER: user
        POSTGRES_PASSWORD: testing-password
        POSTGRES_ENABLED: "true"
        POSTGRES_DB: $CI_ENVIRONMENT_SLUG
      HEREDOC
    end

    let(:remote_file_hash) do
      YAML.safe_load(remote_file_content).deep_symbolize_keys
    end

    let(:gitlab_ci_yml) do
      <<~HEREDOC
      include:
        - #{local_location}
        - #{remote_location}
        - project: '$MAIN_PROJECT'
          ref: '$REF'
          file: '$FILENAME'
      image: image:1.0
      HEREDOC
    end

    let(:config) do
      described_class.new(gitlab_ci_yml, project: project, pipeline: pipeline, sha: project_sha, user: user)
    end

    let(:project_files) do
      {
        local_location => local_file_content
      }
    end

    let(:main_project_files) do
      {
        '.gitlab-ci.yml' => local_file_content,
        '.another-ci-file.yml' => local_file_content
      }
    end

    before do
      stub_full_request(remote_location).to_return(body: remote_file_content)

      create(:ci_variable, project: project, key: "REF", value: "HEAD")
      create(:ci_group_variable, group: group, key: "FILENAME", value: ".gitlab-ci.yml")
      create(:ci_instance_variable, key: 'MAIN_PROJECT', value: main_project.full_path)
    end

    around do |example|
      create_and_delete_files(project, project_files) do
        create_and_delete_files(main_project, main_project_files) do
          example.run
        end
      end
    end

    context "when gitlab_ci_yml has valid 'include' defined" do
      it 'returns a composed hash' do
        composed_hash = {
          before_script: local_location_hash[:before_script],
          image: "image:1.0",
          rspec: { script: ["bundle exec rspec"] },
          variables: remote_file_hash[:variables]
        }

        expect(config.to_hash).to eq(composed_hash)
      end

      context 'handling variables' do
        it 'contains all project variables' do
          ref = config.context.variables.find { |v| v[:key] == 'REF' }

          expect(ref[:value]).to eq("HEAD")
        end

        it 'contains all group variables' do
          filename = config.context.variables.find { |v| v[:key] == 'FILENAME' }

          expect(filename[:value]).to eq(".gitlab-ci.yml")
        end

        it 'contains all instance variables' do
          project = config.context.variables.find { |v| v[:key] == 'MAIN_PROJECT' }

          expect(project[:value]).to eq(main_project.full_path)
        end

        context 'overriding a group variable at project level' do
          before do
            create(:ci_variable, project: project, key: "FILENAME", value: ".another-ci-file.yml")
          end

          it 'successfully overrides' do
            filename = config.context.variables.to_hash[:FILENAME]

            expect(filename).to eq('.another-ci-file.yml')
          end
        end
      end

      it 'stores includes' do
        expect(config.metadata[:includes]).to contain_exactly(
          { type: :local,
            location: local_location,
            blob: "http://localhost/#{project.full_path}/-/blob/#{project_sha}/#{local_location}",
            raw: "http://localhost/#{project.full_path}/-/raw/#{project_sha}/#{local_location}",
            extra: {},
            context_project: project.full_path,
            context_sha: project_sha },
          { type: :remote,
            location: remote_location,
            blob: nil,
            raw: remote_location,
            extra: {},
            context_project: project.full_path,
            context_sha: project_sha },
          { type: :file,
            location: '.gitlab-ci.yml',
            blob: "http://localhost/#{main_project.full_path}/-/blob/#{main_project_sha}/.gitlab-ci.yml",
            raw: "http://localhost/#{main_project.full_path}/-/raw/#{main_project_sha}/.gitlab-ci.yml",
            extra: { project: main_project.full_path, ref: 'HEAD' },
            context_project: project.full_path,
            context_sha: project_sha }
        )
      end
    end

    context "when gitlab_ci.yml has invalid 'include' defined" do
      let(:gitlab_ci_yml) do
        <<~HEREDOC
          include: invalid
        HEREDOC
      end

      it 'raises ConfigError' do
        expect { config }.to raise_error(
          described_class::ConfigError,
          "Included file `invalid` does not have YAML extension!"
        )
      end
    end

    context "when gitlab_ci.yml has ambigious 'include' defined" do
      let(:gitlab_ci_yml) do
        <<~HEREDOC
          include:
            remote: http://url
            local: /local/file.yml
        HEREDOC
      end

      it 'raises ConfigError' do
        expect { config }.to raise_error(
          described_class::ConfigError,
          /Each include must use only one of/
        )
      end
    end

    context "when it takes too long to evaluate includes" do
      before do
        allow_next_instance_of(Gitlab::Ci::Config::External::Context) do |instance|
          allow(instance).to receive(:check_execution_time!).and_call_original
          allow(instance).to receive(:set_deadline).with(described_class::TIMEOUT_SECONDS).and_call_original
          allow(instance).to receive(:execution_expired?).and_return(true)
        end
      end

      it 'raises error TimeoutError' do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

        expect { config }.to raise_error(
          described_class::ConfigError,
          'Request timed out when fetching configuration files.'
        )
      end
    end

    describe 'external file version' do
      context 'when external local file SHA is defined' do
        it 'is using a defined value' do
          described_class.new(gitlab_ci_yml, project: project, sha: project_sha, user: user, pipeline: pipeline)
        end
      end

      context 'when external local file SHA is not defined' do
        it 'is using latest SHA on the default branch' do
          expect(project.repository).to receive(:root_ref_sha).and_call_original

          described_class.new(gitlab_ci_yml, project: project, sha: nil, user: user, pipeline: pipeline)
        end
      end
    end

    context "when both external files and gitlab_ci.yml defined the same key" do
      let(:gitlab_ci_yml) do
        <<~HEREDOC
        include:
          - #{remote_location}

        image: image:1.0
        HEREDOC
      end

      let(:remote_file_content) do
        <<~HEREDOC
        image: php:5-fpm-alpine
        HEREDOC
      end

      it 'takes precedence' do
        expect(config.to_hash).to eq({ image: 'image:1.0' })
      end
    end

    context "when both external files and gitlab_ci.yml define a dictionary of distinct variables" do
      let(:remote_file_content) do
        <<~HEREDOC
        variables:
          A: 'alpha'
          B: 'beta'
        HEREDOC
      end

      let(:gitlab_ci_yml) do
        <<~HEREDOC
        include:
          - #{remote_location}

        variables:
          C: 'gamma'
          D: 'delta'
        HEREDOC
      end

      it 'merges the variables dictionaries' do
        expect(config.to_hash).to eq({ variables: { A: 'alpha', B: 'beta', C: 'gamma', D: 'delta' } })
      end
    end

    context "when both external files and gitlab_ci.yml define a dictionary of overlapping variables" do
      let(:remote_file_content) do
        <<~HEREDOC
        variables:
          A: 'alpha'
          B: 'beta'
          C: 'omnicron'
        HEREDOC
      end

      let(:gitlab_ci_yml) do
        <<~HEREDOC
        include:
          - #{remote_location}

        variables:
          C: 'gamma'
          D: 'delta'
        HEREDOC
      end

      it 'later declarations should take precedence' do
        expect(config.to_hash).to eq({ variables: { A: 'alpha', B: 'beta', C: 'gamma', D: 'delta' } })
      end
    end

    context 'when both external files and gitlab_ci.yml define a job' do
      let(:remote_file_content) do
        <<~HEREDOC
        job1:
          script:
          - echo 'hello from remote file'
        HEREDOC
      end

      let(:gitlab_ci_yml) do
        <<~HEREDOC
        include:
          - #{remote_location}

        job1:
          variables:
            VARIABLE_DEFINED_IN_MAIN_FILE: 'some value'
        HEREDOC
      end

      it 'merges the jobs' do
        expect(config.to_hash).to eq({
          job1: {
            script: ["echo 'hello from remote file'"],
            variables: {
              VARIABLE_DEFINED_IN_MAIN_FILE: 'some value'
            }
          }
        })
      end

      context 'when the script key is in both' do
        let(:gitlab_ci_yml) do
          <<~HEREDOC
          include:
            - #{remote_location}

          job1:
            script:
            - echo 'hello from main file'
            variables:
              VARIABLE_DEFINED_IN_MAIN_FILE: 'some value'
          HEREDOC
        end

        it 'uses the script from the gitlab_ci.yml' do
          expect(config.to_hash).to eq({
            job1: {
              script: ["echo 'hello from main file'"],
              variables: {
                VARIABLE_DEFINED_IN_MAIN_FILE: 'some value'
              }
            }
          })
        end
      end
    end

    context 'when including file from artifact' do
      let(:config) do
        described_class.new(
          gitlab_ci_yml,
          project: nil,
          sha: nil,
          user: nil,
          parent_pipeline: parent_pipeline)
      end

      let(:gitlab_ci_yml) do
        <<~HEREDOC
        include:
          - artifact: generated.yml
            job: rspec
        HEREDOC
      end

      let(:parent_pipeline) { nil }

      context 'when used in the context of a child pipeline' do
        # This job has ci_build_artifacts.zip artifact archive which
        # contains generated.yml
        let!(:job) { create(:ci_build, :artifacts, name: 'rspec', pipeline: parent_pipeline) }
        let(:parent_pipeline) { create(:ci_pipeline) }

        it 'returns valid config' do
          expect(config).to be_valid
        end

        context 'when job key is missing' do
          let(:gitlab_ci_yml) do
            <<~HEREDOC
            include:
              - artifact: generated.yml
            HEREDOC
          end

          it 'raises an error' do
            expect { config }.to raise_error(
              described_class::ConfigError,
              'Job must be provided when including configs from artifacts'
            )
          end
        end

        context 'when artifact key is missing' do
          let(:gitlab_ci_yml) do
            <<~HEREDOC
            include:
              - job: rspec
            HEREDOC
          end

          it 'raises an error' do
            expect { config }.to raise_error(
              described_class::ConfigError,
              /does not have a valid subkey for include/
            )
          end
        end
      end

      it 'disallows the use in parent pipelines' do
        expect { config }.to raise_error(
          described_class::ConfigError,
          'Including configs from artifacts is only allowed when triggering child pipelines'
        )
      end
    end

    context "when including multiple files from a project" do
      let(:other_file_location) { 'my_builds.yml' }

      let(:other_file_content) do
        <<~HEREDOC
        build:
          stage: build
          script: echo hello

        rspec:
          stage: test
          script: bundle exec rspec
        HEREDOC
      end

      let(:gitlab_ci_yml) do
        <<~HEREDOC
        include:
          - project: #{project.full_path}
            file:
              - #{local_location}
              - #{other_file_location}

        image: image:1.0
        HEREDOC
      end

      before do
        project.add_developer(user)
      end

      around do |example|
        create_and_delete_files(project, { other_file_location => other_file_content }) do
          example.run
        end
      end

      it 'returns a composed hash' do
        composed_hash = {
          before_script: local_location_hash[:before_script],
          image: "image:1.0",
          build: { stage: "build", script: "echo hello" },
          rspec: { stage: "test", script: "bundle exec rspec" }
        }

        expect(config.to_hash).to eq(composed_hash)
      end
    end

    context "when an 'include' has rules" do
      context "when the rule is an if" do
        let(:gitlab_ci_yml) do
          <<~HEREDOC
          include:
            - local: #{local_location}
              rules:
                - if: $CI_PROJECT_ID == "#{project_id}"
          image: image:1.0
          HEREDOC
        end

        context 'when the rules condition is satisfied' do
          let(:project_id) { project.id }

          it 'includes the file' do
            expect(config.to_hash).to include(local_location_hash)
          end
        end

        context 'when the rules condition is satisfied' do
          let(:project_id) { non_existing_record_id }

          it 'does not include the file' do
            expect(config.to_hash).not_to include(local_location_hash)
          end
        end
      end

      context "when the rule is an exists" do
        let(:gitlab_ci_yml) do
          <<~HEREDOC
          include:
            - local: #{local_location}
              rules:
                - exists: "#{filename}"
          image: image:1.0
          HEREDOC
        end

        around do |example|
          create_and_delete_files(project, { 'my_builds.yml' => local_file_content }) do
            example.run
          end
        end

        context 'when the exists file does not exist' do
          let(:filename) { 'not_a_real_file.md' }

          it 'does not include the file' do
            expect(config.to_hash).not_to include(local_location_hash)
          end
        end

        context 'when the exists file does exist' do
          let(:filename) { 'my_builds.yml' }

          it 'does include the file' do
            expect(config.to_hash).to include(local_location_hash)
          end
        end
      end
    end

    context "when an 'include' has rules with a pipeline variable" do
      let(:gitlab_ci_yml) do
        <<~HEREDOC
        include:
          - local: #{local_location}
            rules:
              - if: $CI_COMMIT_REF_NAME == "master"
        HEREDOC
      end

      context 'when a pipeline is passed' do
        it 'includes the file' do
          expect(config.to_hash).to include(local_location_hash)
        end
      end

      context 'when a pipeline is not passed' do
        let(:pipeline) { nil }

        it 'does not include the file' do
          expect(config.to_hash).not_to include(local_location_hash)
        end
      end
    end
  end

  describe '#workflow_rules' do
    subject(:workflow_rules) { config.workflow_rules }

    let(:yml) do
      <<-EOS
        workflow:
          rules:
            - if: $CI_COMMIT_REF_NAME == "master"

        rspec:
          script: exit 0
      EOS
    end

    it { is_expected.to eq([{ if: '$CI_COMMIT_REF_NAME == "master"' }]) }
  end

  describe '#workflow_name' do
    subject(:workflow_name) { config.workflow_name }

    let(:yml) do
      <<-EOS
        workflow:
          name: 'Pipeline name'

        rspec:
          script: exit 0
      EOS
    end

    it { is_expected.to eq('Pipeline name') }

    context 'with no name' do
      let(:yml) do
        <<-EOS
          rspec:
            script: exit 0
        EOS
      end

      it { is_expected.to be_nil }
    end
  end
end
