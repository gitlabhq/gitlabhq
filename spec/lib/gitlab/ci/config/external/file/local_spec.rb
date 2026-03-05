# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::File::Local, feature_category: :pipeline_composition do
  include RepoHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:sha) { project.commit.sha }
  let(:variables) { project.predefined_variables.to_runner_variables }
  let(:context) { Gitlab::Ci::Config::External::Context.new(**context_params) }
  let(:params) { { local: location } }
  let(:local_file) { described_class.new(params, context) }
  let(:parent_pipeline) { double(:parent_pipeline) }

  let(:context_params) do
    {
      project: project,
      sha: sha,
      user: user,
      parent_pipeline: parent_pipeline,
      variables: variables
    }
  end

  before do
    allow_any_instance_of(Gitlab::Ci::Config::External::Context)
      .to receive(:check_execution_time!)
  end

  describe '.initialize' do
    context 'when a local is specified' do
      let(:params) { { local: 'file' } }

      it 'sets the location' do
        expect(local_file.location).to eq('file')
      end

      context 'when the local is prefixed with a slash' do
        let(:params) { { local: '/file' } }

        it 'removes the slash' do
          expect(local_file.location).to eq('file')
        end
      end

      context 'when the local is prefixed with multiple slashes' do
        let(:params) { { local: '//file' } }

        it 'removes slashes' do
          expect(local_file.location).to eq('file')
        end
      end
    end

    context 'with a missing local' do
      let(:params) { { local: nil } }

      it 'sets the location to an empty string' do
        expect(local_file.location).to eq('')
      end
    end
  end

  describe '#matching?' do
    context 'when a local is specified' do
      let(:params) { { local: 'file' } }

      it 'returns true' do
        expect(local_file).to be_matching
      end
    end

    context 'with a missing local' do
      let(:params) { { local: nil } }

      it 'returns false' do
        expect(local_file).not_to be_matching
      end
    end

    context 'with a missing local key' do
      let(:params) { {} }

      it 'returns false' do
        expect(local_file).not_to be_matching
      end
    end
  end

  describe '#valid?' do
    subject(:valid?) do
      Gitlab::Ci::Config::External::Mapper::Verifier.new(context).process([local_file])
      local_file.valid?
    end

    context 'when is a valid local path' do
      let(:location) { '/lib/gitlab/ci/templates/existent-file.yml' }

      before do
        allow_any_instance_of(described_class).to receive(:fetch_local_content).and_return("image: 'ruby2:2'")
      end

      it { is_expected.to be_truthy }
    end

    context 'when it is not a valid local path' do
      let(:location) { '/lib/gitlab/ci/templates/non-existent-file.yml' }

      it { is_expected.to be_falsy }
    end

    context 'when it is not a yaml file' do
      let(:location) { '/config/application.rb' }

      it { is_expected.to be_falsy }
    end

    context 'when it is an empty file' do
      let(:variables) { Gitlab::Ci::Variables::Collection.new([{ 'key' => 'GITLAB_TOKEN', 'value' => 'secret', 'masked' => true }]) }
      let(:location) { '/lib/gitlab/ci/templates/secret/existent-file.yml' }

      before do
        allow_any_instance_of(described_class).to receive(:fetch_local_content).and_return("")
      end

      it 'returns false and adds an error message about an empty file' do
        expect(valid?).to be_falsy
        expect(local_file.errors).to include("Local file `lib/gitlab/ci/templates/xxxxxx/existent-file.yml` is empty!")
      end
    end

    context 'when included file uses spec:include' do
      let(:location) { '/lib/gitlab/ci/templates/existent-file.yml' }

      before do
        allow_any_instance_of(described_class)
          .to receive(:fetch_local_content)
          .and_return("spec:\n  include:\n    - local: /shared-inputs.yml\n---\njob:\n  script: echo\n")
      end

      it 'returns false and adds an error message about spec:include not being supported' do
        expect(valid?).to be_falsy
        expect(local_file.errors).to include(
          "Included file `lib/gitlab/ci/templates/existent-file.yml` cannot use `spec:include`. " \
            "This keyword is not supported in included configuration files"
        )
      end

      context 'when the file is an internal include (trigger:include)' do
        let(:pipeline_config) { instance_double(Gitlab::Ci::ProjectConfig::Bridge, internal_include_prepended?: true) }
        let(:context_params) do
          {
            project: project,
            sha: sha,
            user: user,
            parent_pipeline: parent_pipeline,
            variables: variables,
            pipeline_config: pipeline_config
          }
        end

        it 'does not add a spec:include validation error' do
          local_file.validate_spec_include!

          expect(local_file.errors).not_to include(
            a_string_matching(/cannot use `spec:include`/)
          )
        end

        context 'when the file is included by the child pipeline config (nested include)' do
          let(:nested_context) { context.mutate(project: project, sha: sha, user: user, variables: variables) }
          let(:nested_file) { described_class.new(params, nested_context) }

          it 'blocks spec:include because internal_include? is not preserved for nested contexts' do
            nested_file.validate_spec_include!

            expect(nested_file.errors).to include(
              a_string_matching(/cannot use `spec:include`/)
            )
          end
        end
      end
    end

    context 'when the given sha is not valid' do
      let(:location) { '/lib/gitlab/ci/templates/existent-file.yml' }
      let(:sha) { ':' }

      it 'returns false and adds an error message stating that included file does not exist' do
        expect(valid?).to be_falsy
        expect(local_file.errors).to include("Local file `lib/gitlab/ci/templates/existent-file.yml` does not exist!")
      end
    end
  end

  describe '#content' do
    context 'with a valid file' do
      let(:local_file_content) do
        <<~HEREDOC
          before_script:
            - apt-get update -qq && apt-get install -y -qq sqlite3 libsqlite3-dev nodejs
            - ruby -v
            - which ruby
            - bundle install --jobs $(nproc)  "${FLAGS[@]}"
        HEREDOC
      end

      let(:location) { '/lib/gitlab/ci/templates/existent-file.yml' }

      before do
        allow_any_instance_of(described_class).to receive(:fetch_local_content).and_return(local_file_content)
      end

      it 'returns the content of the file' do
        expect(local_file.content).to eq(local_file_content)
      end
    end

    context 'with an invalid file' do
      let(:location) { '/lib/gitlab/ci/templates/non-existent-file.yml' }

      it 'is nil' do
        expect(local_file.content).to be_nil
      end
    end
  end

  describe '#error_message' do
    let(:location) { '/lib/gitlab/ci/templates/secret_file.yml' }
    let(:variables) { Gitlab::Ci::Variables::Collection.new([{ 'key' => 'GITLAB_TOKEN', 'value' => 'secret_file', 'masked' => true }]) }

    before do
      Gitlab::Ci::Config::External::Mapper::Verifier.new(context).process([local_file])
    end

    it 'returns an error message with the variable masked' do
      expect(local_file.error_message).to eq("Local file `lib/gitlab/ci/templates/[MASKED]xxx.yml` does not exist!")
    end
  end

  describe '#expand_context' do
    let(:location) { 'location.yml' }

    subject { local_file.send(:expand_context_attrs) }

    it 'inherits project, user and sha' do
      is_expected.to include(
        user: user,
        project: project,
        sha: sha,
        parent_pipeline: parent_pipeline,
        variables: project.predefined_variables.to_runner_variables)
    end
  end

  describe '#to_hash' do
    context 'properly includes another local file in the same repository' do
      let(:location) { 'some/file/config.yml' }
      let(:content) { 'include: { local: another-config.yml }' }

      let(:another_location) { 'another-config.yml' }
      let(:another_content) { 'rspec: JOB' }

      let(:project_files) do
        {
          location => content,
          another_location => another_content
        }
      end

      around do |example|
        create_and_delete_files(project, project_files) do
          example.run
        end
      end

      it 'does expand hash to include the template' do
        expect(local_file.to_hash).to include(:rspec)
      end
    end

    context 'when interpolaton is being used' do
      let(:local_file_content) do
        <<~YAML
          spec:
            inputs:
              website:
          ---
          test:
            script: cap deploy $[[ inputs.website ]]
        YAML
      end

      let(:location) { '/lib/gitlab/ci/templates/existent-file.yml' }
      let(:params) { { local: location, inputs: { website: 'gitlab.com' } } }

      before do
        allow_any_instance_of(described_class)
          .to receive(:fetch_local_content)
          .and_return(local_file_content)
      end

      it 'correctly interpolates the local template' do
        expect(local_file).to be_valid
        expect(local_file.to_hash)
          .to eq({ test: { script: 'cap deploy gitlab.com' } })
      end
    end
  end

  describe '#metadata' do
    let(:location) { '/lib/gitlab/ci/templates/existent-file.yml' }

    subject(:metadata) { local_file.metadata }

    it do
      is_expected.to eq(
        context_project: project.full_path,
        context_sha: sha,
        type: :local,
        location: 'lib/gitlab/ci/templates/existent-file.yml',
        blob: "http://#{Gitlab.config.gitlab.host}/#{project.full_path}/-/blob/#{sha}/lib/gitlab/ci/templates/existent-file.yml",
        raw: "http://#{Gitlab.config.gitlab.host}/#{project.full_path}/-/raw/#{sha}/lib/gitlab/ci/templates/existent-file.yml",
        extra: {}
      )
    end
  end

  describe 'logging' do
    let(:location) { '/lib/gitlab/ci/templates/existent-file.yml' }
    let(:expected_path) { 'lib/gitlab/ci/templates/existent-file.yml' }
    let(:blob) { instance_double(Gitlab::Git::Blob, commit_id: sha, path: expected_path, data: 'content') }

    subject(:process_file) { Gitlab::Ci::Config::External::Mapper::Verifier.new(context).process([local_file]) }

    before do
      allow(project.repository).to receive(:blobs_at).and_return([])
      allow(Gitlab::AppLogger).to receive(:warn)
    end

    describe 'verbose logging with feature flag' do
      context 'when ci_config_local_file_verbose_logging is enabled' do
        before do
          Feature.enable(:ci_config_local_file_verbose_logging)
        end

        it 'logs blob request at info level' do
          expect(Gitlab::AppLogger).to receive(:info).with(hash_including(
            'message' => 'CI config: Fetching blobs from Gitaly',
            'project_id' => project.id
          ))

          process_file
        end

        it 'logs nil content at warn level when file does not exist' do
          expect(Gitlab::AppLogger).to receive(:warn).with(hash_including(
            'message' => 'CI config: Local file content is nil',
            'extra' => hash_including(location: expected_path)
          ))

          process_file
        end

        it 'logs successful blob response at info level when no paths are missing' do
          allow(project.repository).to receive(:blobs_at).and_return([blob])

          expect(Gitlab::AppLogger).to receive(:info).with(hash_including(
            'message' => 'CI config: Fetching blobs from Gitaly'
          ))
          expect(Gitlab::AppLogger).to receive(:info).with(hash_including(
            'message' => 'CI config: Blobs fetched from Gitaly',
            'extra' => hash_including(returned_count: 1)
          ))

          process_file
        end
      end

      context 'when ci_config_local_file_verbose_logging is disabled' do
        before do
          Feature.disable(:ci_config_local_file_verbose_logging)
        end

        it 'does not log blob request' do
          expect(Gitlab::AppLogger).not_to receive(:info).with(hash_including(
            'message' => 'CI config: Fetching blobs from Gitaly'
          ))

          process_file
        end

        it 'does not log any info messages on successful blob fetch' do
          allow(project.repository).to receive(:blobs_at).and_return([blob])

          expect(Gitlab::AppLogger).not_to receive(:info)
          expect(Gitlab::AppLogger).not_to receive(:warn)

          process_file
        end
      end
    end

    describe 'failure logging (always enabled)' do
      before do
        Feature.disable(:ci_config_local_file_verbose_logging)
      end

      it 'logs missing paths at warn level regardless of feature flag' do
        expect(Gitlab::AppLogger).to receive(:warn).with(hash_including(
          'message' => 'CI config: Blobs fetched from Gitaly - missing paths detected',
          'extra' => hash_including(
            missing_count: 1,
            missing_paths: [expected_path]
          )
        ))
        expect(Gitlab::AppLogger).not_to receive(:warn).with(hash_including(
          'message' => 'CI config: Local file content is nil'
        ))

        process_file
      end

      it 'logs GRPC errors at warn level regardless of feature flag' do
        allow(project.repository).to receive(:blobs_at).and_raise(GRPC::InvalidArgument.new('test error'))

        expect(Gitlab::AppLogger).to receive(:warn).with(hash_including(
          'message' => 'CI config: GRPC error fetching blobs',
          'extra' => hash_including(error_class: 'GRPC::InvalidArgument')
        ))

        process_file
      end
    end
  end
end
