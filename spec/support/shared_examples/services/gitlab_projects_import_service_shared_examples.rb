# frozen_string_literal: true

RSpec.shared_examples 'gitlab projects import validations' do |import_type:|
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
      expect(project.import_type).to eq(import_type.to_s)
    end
  end

  context 'with override params' do
    let(:override_params) { { description: 'Hello', name: 'Name override' } }

    before do
      import_params.delete(:name)
    end

    it 'stores them as import data when passed' do
      project = described_class
                  .new(namespace.owner, import_params, override_params, import_type: import_type)
                  .execute

      expect(project.import_data.data['override_params']).to eq(override_params.stringify_keys)
    end

    context 'and name is not in override params' do
      let(:override_params) { { description: 'Hello' } }

      it 'does not store name in import data' do
        project = described_class
                    .new(namespace.owner, import_params, override_params, import_type: import_type)
                    .execute

        expect(project.import_data.data['override_params']).not_to include('name')
      end
    end
  end

  context 'with name attribute' do
    before do
      import_params[:name] = 'Test project'
    end

    it 'stores name in import data to prevent overwrite on import' do
      project = subject.execute

      expect(project.import_data.data['override_params']['name']).to eq('Test project')
    end

    context 'and name is in override params' do
      it 'stores name from override params to import data' do
        project = described_class
                    .new(namespace.owner, import_params, { name: 'Name override' }, import_type: import_type)
                    .execute

        expect(project.import_data.data['override_params']['name']).to eq('Name override')
      end
    end
  end

  context 'without name attribute or override params' do
    it 'does not store name in import data' do
      import_params.delete(:name)

      project = subject.execute

      expect(project.import_data&.data&.dig('override_params', 'name')).to be_nil
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
