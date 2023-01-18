# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::File::Local, feature_category: :pipeline_authoring do
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
      local_file.validate!
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

      it 'returns false and adds an error message about an empty file' do
        allow_any_instance_of(described_class).to receive(:fetch_local_content).and_return("")
        local_file.validate!
        expect(local_file.errors).to include("Local file `/lib/gitlab/ci/templates/xxxxxx/existent-file.yml` is empty!")
      end
    end

    context 'when the given sha is not valid' do
      let(:location) { '/lib/gitlab/ci/templates/existent-file.yml' }
      let(:sha) { ':' }

      it 'returns false and adds an error message stating that included file does not exist' do
        expect(valid?).to be_falsy
        expect(local_file.errors).to include("Sha #{sha} is not valid!")
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
      local_file.validate!
    end

    it 'returns an error message' do
      expect(local_file.error_message).to eq("Local file `/lib/gitlab/ci/templates/xxxxxxxxxxx.yml` does not exist!")
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

      around(:all) do |example|
        create_and_delete_files(project, project_files) do
          example.run
        end
      end

      it 'does expand hash to include the template' do
        expect(local_file.to_hash).to include(:rspec)
      end
    end
  end

  describe '#metadata' do
    let(:location) { '/lib/gitlab/ci/templates/existent-file.yml' }

    subject(:metadata) { local_file.metadata }

    it {
      is_expected.to eq(
        context_project: project.full_path,
        context_sha: sha,
        type: :local,
        location: '/lib/gitlab/ci/templates/existent-file.yml',
        blob: "http://localhost/#{project.full_path}/-/blob/#{sha}/lib/gitlab/ci/templates/existent-file.yml",
        raw: "http://localhost/#{project.full_path}/-/raw/#{sha}/lib/gitlab/ci/templates/existent-file.yml",
        extra: {}
      )
    }
  end
end
