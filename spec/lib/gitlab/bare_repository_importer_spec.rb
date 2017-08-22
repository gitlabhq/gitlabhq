require 'spec_helper'

describe Gitlab::BareRepositoryImporter, repository: true do
  subject(:importer) { described_class.new('default', project_path) }
  let(:project_path) { 'a-group/a-sub-group/a-project' }
  let!(:admin) { create(:admin) }

  before do
    allow(described_class).to receive(:log)
  end

  describe '.execute' do
    it 'creates a project for a repository in storage' do
      FileUtils.mkdir_p(File.join(TestEnv.repos_path, "#{project_path}.git"))
      fake_importer = double

      expect(described_class).to receive(:new).with('default', project_path)
                                   .and_return(fake_importer)
      expect(fake_importer).to receive(:create_project_if_needed)

      described_class.execute
    end

    it 'skips wiki repos' do
      FileUtils.mkdir_p(File.join(TestEnv.repos_path, 'the-group', 'the-project.wiki.git'))

      expect(described_class).to receive(:log).with(' * Skipping wiki repo')
      expect(described_class).not_to receive(:new)

      described_class.execute
    end
  end

  describe '#initialize' do
    context 'without admin users' do
      let(:admin) { nil }

      it 'raises an error' do
        expect { importer }.to raise_error(Gitlab::BareRepositoryImporter::NoAdminError)
      end
    end
  end

  describe '#create_project_if_needed' do
    it 'starts an import for a project that did not exist' do
      expect(importer).to receive(:create_project)

      importer.create_project_if_needed
    end

    it 'skips importing when the project already exists' do
      group = create(:group, path: 'a-group')
      subgroup = create(:group, path: 'a-sub-group', parent: group)
      project = create(:project, path: 'a-project', namespace: subgroup)

      expect(importer).not_to receive(:create_project)
      expect(importer).to receive(:log).with(" * #{project.name} (a-group/a-sub-group/a-project) exists")

      importer.create_project_if_needed
    end

    it 'creates a project with the correct path in the database' do
      importer.create_project_if_needed

      expect(Project.find_by_full_path(project_path)).not_to be_nil
    end
  end
end
