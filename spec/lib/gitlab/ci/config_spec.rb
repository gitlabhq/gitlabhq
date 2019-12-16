# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Config do
  include StubRequests

  set(:user) { create(:user) }

  before do
    allow_next_instance_of(Gitlab::Ci::Config::External::Context) do |instance|
      allow(instance).to receive(:check_execution_time!)
    end
  end

  let(:config) do
    described_class.new(yml, project: nil, sha: nil, user: nil)
  end

  context 'when config is valid' do
    let(:yml) do
      <<-EOS
        image: ruby:2.2

        rspec:
          script:
            - gem install rspec
            - rspec
      EOS
    end

    describe '#to_hash' do
      it 'returns hash created from string' do
        hash = {
          image: 'ruby:2.2',
          rspec: {
            script: ['gem install rspec',
                     'rspec']
          }
        }

        expect(config.to_hash).to eq hash
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

      context 'with feature disabled' do
        before do
          stub_feature_flags(ci_pre_post_pipeline_stages: false)
        end

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

        it { is_expected.to eq %w[stage1 stage2] }
      end
    end
  end

  context 'when using extendable hash' do
    let(:yml) do
      <<-EOS
        image: ruby:2.2

        rspec:
          script: rspec

        test:
          extends: rspec
          image: ruby:alpine
      EOS
    end

    it 'correctly extends the hash' do
      hash = {
        image: 'ruby:2.2',
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
              name: ruby:2.2
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
            image: ruby:2.2

            test:
              script: rspec
              image:
                name: ruby:2.2
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
            image: ruby:2.2

            test:
              script: rspec
              image: ruby:2.2
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
  end

  context "when using 'include' directive" do
    let(:project) { create(:project, :repository) }
    let(:remote_location) { 'https://gitlab.com/gitlab-org/gitlab-foss/blob/1234/.gitlab-ci-1.yml' }
    let(:local_location) { 'spec/fixtures/gitlab/ci/external_files/.gitlab-ci-template-1.yml' }

    let(:remote_file_content) do
      <<~HEREDOC
      variables:
        POSTGRES_USER: user
        POSTGRES_PASSWORD: testing-password
        POSTGRES_ENABLED: "true"
        POSTGRES_DB: $CI_ENVIRONMENT_SLUG
      HEREDOC
    end

    let(:local_file_content) do
      File.read(Rails.root.join(local_location))
    end

    let(:gitlab_ci_yml) do
      <<~HEREDOC
      include:
        - #{local_location}
        - #{remote_location}

      image: ruby:2.2
      HEREDOC
    end

    let(:config) do
      described_class.new(gitlab_ci_yml, project: project, sha: '12345', user: user)
    end

    before do
      stub_full_request(remote_location).to_return(body: remote_file_content)

      allow(project.repository)
        .to receive(:blob_data_at).and_return(local_file_content)
    end

    context "when gitlab_ci_yml has valid 'include' defined" do
      it 'returns a composed hash' do
        before_script_values = [
          "apt-get update -qq && apt-get install -y -qq sqlite3 libsqlite3-dev nodejs", "ruby -v",
          "which ruby",
          "bundle install --jobs $(nproc)  \"${FLAGS[@]}\""
        ]
        variables = {
          POSTGRES_USER: "user",
          POSTGRES_PASSWORD: "testing-password",
          POSTGRES_ENABLED: "true",
          POSTGRES_DB: "$CI_ENVIRONMENT_SLUG"
        }
        composed_hash = {
          before_script: before_script_values,
          image: "ruby:2.2",
          rspec: { script: ["bundle exec rspec"] },
          variables: variables
        }

        expect(config.to_hash).to eq(composed_hash)
      end
    end

    context "when gitlab_ci.yml has invalid 'include' defined" do
      let(:gitlab_ci_yml) do
        <<~HEREDOC
          include: invalid
        HEREDOC
      end

      it 'raises error YamlProcessor validationError' do
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

      it 'raises error YamlProcessor validationError' do
        expect { config }.to raise_error(
          described_class::ConfigError,
          'Include `{"remote":"http://url","local":"/local/file.yml"}` needs to match exactly one accessor!'
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
          'Resolving config took longer than expected'
        )
      end
    end

    context 'when context expansion timeout is disabled' do
      before do
        allow_next_instance_of(Gitlab::Ci::Config::External::Context) do |instance|
          allow(instance).to receive(:check_execution_time!).and_call_original
        end

        allow(Feature)
          .to receive(:enabled?)
          .with(:ci_limit_yaml_expansion, project, default_enabled: true)
          .and_return(false)
      end

      it 'does not raises errors' do
        expect { config }.not_to raise_error
      end
    end

    describe 'external file version' do
      context 'when external local file SHA is defined' do
        it 'is using a defined value' do
          expect(project.repository).to receive(:blob_data_at)
            .with('eeff1122', local_location)

          described_class.new(gitlab_ci_yml, project: project, sha: 'eeff1122', user: user)
        end
      end

      context 'when external local file SHA is not defined' do
        it 'is using latest SHA on the default branch' do
          expect(project.repository).to receive(:root_ref_sha)

          described_class.new(gitlab_ci_yml, project: project, sha: nil, user: user)
        end
      end
    end

    context "when both external files and gitlab_ci.yml defined the same key" do
      let(:gitlab_ci_yml) do
        <<~HEREDOC
        include:
          - #{remote_location}

        image: ruby:2.2
        HEREDOC
      end

      let(:remote_file_content) do
        <<~HEREDOC
        image: php:5-fpm-alpine
        HEREDOC
      end

      it 'takes precedence' do
        expect(config.to_hash).to eq({ image: 'ruby:2.2' })
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
  end
end
