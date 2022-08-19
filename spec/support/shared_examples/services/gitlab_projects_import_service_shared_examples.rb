# frozen_string_literal: true

RSpec.shared_examples 'gitlab projects import validations' do
  context 'with an invalid path' do
    let(:path) { '/invalid-path/' }

    it 'returns an invalid project' do
      project = subject.execute

      expect(project).not_to be_persisted
      expect(project).not_to be_valid
    end
  end

  context 'with a valid path' do
    it 'creates a project' do
      project = subject.execute

      expect(project).to be_persisted
      expect(project).to be_valid
    end
  end

  context 'override params' do
    it 'stores them as import data when passed' do
      project = described_class
                  .new(namespace.owner, import_params, description: 'Hello')
                  .execute

      expect(project.import_data.data['override_params']['description']).to eq('Hello')
    end
  end

  context 'when there is a project with the same path' do
    let(:existing_project) { create(:project, namespace: namespace) }
    let(:path) { existing_project.path }

    it 'does not create the project' do
      project = subject.execute

      expect(project).to be_invalid
      expect(project).not_to be_persisted
    end

    context 'when overwrite param is set' do
      let(:overwrite) { true }

      it 'creates a project in a temporary full_path' do
        project = subject.execute

        expect(project).to be_valid
        expect(project).to be_persisted
      end
    end
  end
end
