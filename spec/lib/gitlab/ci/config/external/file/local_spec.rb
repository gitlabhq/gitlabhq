# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::File::Local do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:sha) { '12345' }
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
      variables: project.predefined_variables.to_runner_variables
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
    context 'when is a valid local path' do
      let(:location) { '/lib/gitlab/ci/templates/existent-file.yml' }

      before do
        allow_any_instance_of(described_class).to receive(:fetch_local_content).and_return("image: 'ruby2:2'")
      end

      it 'returns true' do
        expect(local_file.valid?).to be_truthy
      end
    end

    context 'when is not a valid local path' do
      let(:location) { '/lib/gitlab/ci/templates/non-existent-file.yml' }

      it 'returns false' do
        expect(local_file.valid?).to be_falsy
      end
    end

    context 'when is not a yaml file' do
      let(:location) { '/config/application.rb' }

      it 'returns false' do
        expect(local_file.valid?).to be_falsy
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
    let(:location) { '/lib/gitlab/ci/templates/non-existent-file.yml' }

    it 'returns an error message' do
      expect(local_file.error_message).to eq("Local file `#{location}` does not exist!")
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
      let(:content) { 'include: { local: another-config.yml }'}

      let(:another_location) { 'another-config.yml' }
      let(:another_content) { 'rspec: JOB' }

      before do
        allow(project.repository).to receive(:blob_data_at).with(sha, location)
          .and_return(content)

        allow(project.repository).to receive(:blob_data_at).with(sha, another_location)
          .and_return(another_content)
      end

      it 'does expand hash to include the template' do
        expect(local_file.to_hash).to include(:rspec)
      end
    end
  end
end
