# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Config::External::File::Project do
  set(:context_project) { create(:project) }
  set(:project) { create(:project, :repository) }
  set(:user) { create(:user) }

  let(:context_user) { user }
  let(:context_params) { { project: context_project, sha: '12345', user: context_user } }
  let(:context) { Gitlab::Ci::Config::External::Context.new(**context_params) }
  let(:project_file) { described_class.new(params, context) }

  before do
    project.add_developer(user)

    allow_next_instance_of(Gitlab::Ci::Config::External::Context) do |instance|
      allow(instance).to receive(:check_execution_time!)
    end
  end

  describe '#matching?' do
    context 'when a file and project is specified' do
      let(:params) { { file: 'file.yml', project: 'project' } }

      it 'returns true' do
        expect(project_file).to be_matching
      end
    end

    context 'with only file is specified' do
      let(:params) { { file: 'file.yml' } }

      it 'returns false' do
        expect(project_file).not_to be_matching
      end
    end

    context 'with only project is specified' do
      let(:params) { { project: 'project' } }

      it 'returns false' do
        expect(project_file).not_to be_matching
      end
    end

    context 'with a missing local key' do
      let(:params) { {} }

      it 'returns false' do
        expect(project_file).not_to be_matching
      end
    end
  end

  describe '#valid?' do
    context 'when a valid path is used' do
      let(:params) do
        { project: project.full_path, file: '/file.yml' }
      end

      let(:root_ref_sha) { project.repository.root_ref_sha }

      before do
        stub_project_blob(root_ref_sha, '/file.yml') { 'image: ruby:2.1' }
      end

      it 'returns true' do
        expect(project_file).to be_valid
      end

      context 'when user does not have permission to access file' do
        let(:context_user) { create(:user) }

        it 'returns false' do
          expect(project_file).not_to be_valid
          expect(project_file.error_message).to include("Project `#{project.full_path}` not found or access denied!")
        end
      end
    end

    context 'when a valid path with custom ref is used' do
      let(:params) do
        { project: project.full_path, ref: 'master', file: '/file.yml' }
      end

      let(:ref_sha) { project.commit('master').sha }

      before do
        stub_project_blob(ref_sha, '/file.yml') { 'image: ruby:2.1' }
      end

      it 'returns true' do
        expect(project_file).to be_valid
      end
    end

    context 'when an empty file is used' do
      let(:params) do
        { project: project.full_path, file: '/file.yml' }
      end

      let(:root_ref_sha) { project.repository.root_ref_sha }

      before do
        stub_project_blob(root_ref_sha, '/file.yml') { '' }
      end

      it 'returns false' do
        expect(project_file).not_to be_valid
        expect(project_file.error_message).to include("Project `#{project.full_path}` file `/file.yml` is empty!")
      end
    end

    context 'when non-existing ref is used' do
      let(:params) do
        { project: project.full_path, ref: 'I-Do-Not-Exist', file: '/file.yml' }
      end

      it 'returns false' do
        expect(project_file).not_to be_valid
        expect(project_file.error_message).to include("Project `#{project.full_path}` reference `I-Do-Not-Exist` does not exist!")
      end
    end

    context 'when non-existing file is requested' do
      let(:params) do
        { project: project.full_path, file: '/invalid-file.yml' }
      end

      it 'returns false' do
        expect(project_file).not_to be_valid
        expect(project_file.error_message).to include("Project `#{project.full_path}` file `/invalid-file.yml` does not exist!")
      end
    end

    context 'when file is not a yaml file' do
      let(:params) do
        { project: project.full_path, file: '/invalid-file' }
      end

      it 'returns false' do
        expect(project_file).not_to be_valid
        expect(project_file.error_message).to include('Included file `/invalid-file` does not have YAML extension!')
      end
    end
  end

  describe '#expand_context' do
    let(:params) { { file: 'file.yml', project: project.full_path, ref: 'master' } }

    subject { project_file.send(:expand_context_attrs) }

    it 'inherits user, and target project and sha' do
      is_expected.to include(user: user, project: project, sha: project.commit('master').id)
    end
  end

  private

  def stub_project_blob(ref, path)
    allow_next_instance_of(Repository) do |instance|
      allow(instance).to receive(:blob_data_at).with(ref, path) { yield }
    end
  end
end
