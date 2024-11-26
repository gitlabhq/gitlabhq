# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::File::Project, feature_category: :pipeline_composition do
  include RepoHelpers

  let_it_be(:context_project) { create(:project) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:context_user) { user }
  let(:parent_pipeline) { double(:parent_pipeline) }
  let(:context) { Gitlab::Ci::Config::External::Context.new(**context_params) }
  let(:project_file) { described_class.new(params, context) }
  let(:variables) { project.predefined_variables.to_runner_variables }
  let(:project_sha) { project.commit.sha }

  let(:context_params) do
    {
      project: context_project,
      sha: project_sha,
      user: context_user,
      parent_pipeline: parent_pipeline,
      variables: variables
    }
  end

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
    subject(:valid?) do
      Gitlab::Ci::Config::External::Mapper::Verifier.new(context).process([project_file])
      project_file.valid?
    end

    context 'when a valid path is used' do
      let(:params) do
        { project: project.full_path, file: '/file.yml' }
      end

      around do |example|
        create_and_delete_files(project, { '/file.yml' => 'image: image:1.0' }) do
          example.run
        end
      end

      it { is_expected.to be_truthy }

      context 'when user does not have permission to access file' do
        let(:context_user) { create(:user) }

        it 'returns false' do
          expect(valid?).to be_falsy
          expect(project_file.error_message).to include("Project `#{project.full_path}` not found or access denied!")
        end
      end
    end

    context 'when a valid path is used in uppercase' do
      let(:params) do
        { project: project.full_path.upcase, file: '/file.yml' }
      end

      around do |example|
        create_and_delete_files(project, { '/file.yml' => 'image: image:1.0' }) do
          example.run
        end
      end

      it { is_expected.to be_truthy }
    end

    context 'when a valid different case path is used' do
      let_it_be(:project) { create(:project, :repository, path: 'mY-teSt-proJect', name: 'My Test Project') }

      let(:params) do
        { project: "#{project.namespace.full_path}/my-test-projecT", file: '/file.yml' }
      end

      around do |example|
        create_and_delete_files(project, { '/file.yml' => 'image: image:1.0' }) do
          example.run
        end
      end

      it { is_expected.to be_truthy }
    end

    context 'when a valid path with custom ref is used' do
      let(:params) do
        { project: project.full_path, ref: 'master', file: '/file.yml' }
      end

      around do |example|
        create_and_delete_files(project, { '/file.yml' => 'image: image:1.0' }) do
          example.run
        end
      end

      it { is_expected.to be_truthy }
    end

    context 'when an empty file is used' do
      let(:params) do
        { project: project.full_path, file: '/secret_file.yml' }
      end

      let(:variables) { Gitlab::Ci::Variables::Collection.new([{ 'key' => 'GITLAB_TOKEN', 'value' => 'secret_file', 'masked' => true }]) }

      around do |example|
        create_and_delete_files(project, { '/secret_file.yml' => '' }) do
          example.run
        end
      end

      it 'returns false' do
        expect(valid?).to be_falsy
        expect(project_file.error_message).to include("Project `#{project.full_path}` file `[MASKED]xxx.yml` is empty!")
      end
    end

    context 'when non-existing ref is used' do
      let(:params) do
        { project: project.full_path, ref: 'I-Do-Not-Exist', file: '/file.yml' }
      end

      it 'returns false' do
        expect(valid?).to be_falsy
        expect(project_file.error_message).to include("Project `#{project.full_path}` reference `I-Do-Not-Exist` does not exist!")
      end
    end

    context 'when non-existing file is requested' do
      let(:variables) { Gitlab::Ci::Variables::Collection.new([{ 'key' => 'GITLAB_TOKEN', 'value' => 'secret-invalid-file', 'masked' => true }]) }

      let(:params) do
        { project: project.full_path, file: '/secret-invalid-file.yml' }
      end

      it 'returns false' do
        expect(valid?).to be_falsy
        expect(project_file.error_message).to include("Project `#{project.full_path}` file `[MASKED]xxxxxxxxxxx.yml` does not exist!")
      end
    end

    context 'when file is not a yaml file' do
      let(:params) do
        { project: project.full_path, file: '/invalid-file' }
      end

      it 'returns false' do
        expect(valid?).to be_falsy
        expect(project_file.error_message).to include('Included file `invalid-file` does not have YAML extension!')
      end
    end

    context 'when non-existing project is used with a masked variable' do
      let(:variables) do
        Gitlab::Ci::Variables::Collection.new([{ key: 'VAR1', value: 'a_secret_variable_value', masked: true }])
      end

      let(:params) do
        { project: 'a_secret_variable_value', file: '/file.yml' }
      end

      it 'returns false with masked project name' do
        expect(valid?).to be_falsy
        expect(project_file.error_message).to include("Project `[MASKED]xxxxxxxxxxxxxxx` not found or access denied!")
      end
    end

    context 'when a project contained in an array is used with a masked variable' do
      let(:variables) do
        Gitlab::Ci::Variables::Collection.new([{ key: 'VAR1', value: 'a_secret_variable_value', masked: true }])
      end

      let(:params) do
        { project: ['a_secret_variable_value'], file: '/file.yml' }
      end

      it 'does not raise an error' do
        expect { valid? }.not_to raise_error
      end
    end
  end

  describe '#expand_context' do
    let(:params) { { file: 'file.yml', project: project.full_path, ref: 'master' } }

    subject { project_file.send(:expand_context_attrs) }

    it 'inherits user, and target project and sha' do
      is_expected.to include(
        user: user,
        project: project,
        sha: project_sha,
        parent_pipeline: parent_pipeline,
        variables: project.predefined_variables.to_runner_variables)
    end
  end

  describe '#metadata' do
    let(:params) do
      { project: project.full_path, file: '/file.yml' }
    end

    subject(:metadata) { project_file.metadata }

    it do
      is_expected.to eq(
        context_project: context_project.full_path,
        context_sha: project_sha,
        type: :file,
        location: 'file.yml',
        blob: "http://localhost/#{project.full_path}/-/blob/#{project_sha}/file.yml",
        raw: "http://localhost/#{project.full_path}/-/raw/#{project_sha}/file.yml",
        extra: { project: project.full_path, ref: 'HEAD' }
      )
    end

    context 'when project name and ref include masked variables' do
      let_it_be(:project) { create(:project, :repository, path: 'my_project_path') }

      let(:branch_name) { 'merge-commit-analyze-after' }
      let(:namespace_path) { project.namespace.full_path }
      let(:included_project_sha) { project.commit(branch_name).sha }

      let(:variables) do
        Gitlab::Ci::Variables::Collection.new(
          [
            { key: 'VAR1', value: 'my_project_path', masked: true },
            { key: 'VAR2', value: branch_name, masked: true }
          ])
      end

      let(:params) { { project: project.full_path, ref: branch_name, file: '/file.yml' } }

      it do
        is_expected.to eq(
          context_project: context_project.full_path,
          context_sha: project_sha,
          type: :file,
          location: 'file.yml',
          blob: "http://localhost/#{namespace_path}/[MASKED]xxxxxxx/-/blob/#{included_project_sha}/file.yml",
          raw: "http://localhost/#{namespace_path}/[MASKED]xxxxxxx/-/raw/#{included_project_sha}/file.yml",
          extra: { project: "#{namespace_path}/[MASKED]xxxxxxx", ref: '[MASKED]xxxxxxxxxxxxxxxxxx' }
        )
      end
    end
  end

  describe '#to_hash' do
    context 'when interpolation is being used' do
      before do
        project.repository.create_file(
          user,
          'template-file.yml',
          template,
          message: 'Add template',
          branch_name: 'master'
        )
      end

      let(:template) do
        <<~YAML
          spec:
            inputs:
              name:
          ---
          rspec:
            script: rspec --suite $[[ inputs.name ]]
        YAML
      end

      let(:params) do
        { file: 'template-file.yml', ref: 'master', project: project.full_path, inputs: { name: 'abc' } }
      end

      it 'correctly interpolates the content' do
        expect(project_file.to_hash).to eq({ rspec: { script: 'rspec --suite abc' } })
      end
    end
  end
end
