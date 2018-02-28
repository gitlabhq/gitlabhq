require 'spec_helper'

describe Gitlab::BareRepositoryImporter, repository: true do
  subject(:importer) { described_class.new('default', project_path) }

  let!(:admin) { create(:admin) }

  before do
    allow(described_class).to receive(:log)
  end

  shared_examples 'importing a repository' do
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
        project = create(:project, path: 'a-project', namespace: existing_group)

        expect(importer).not_to receive(:create_project)
        expect(importer).to receive(:log).with(" * #{project.name} (#{project_path}) exists")

        importer.create_project_if_needed
      end

      it 'creates a project with the correct path in the database' do
        importer.create_project_if_needed

        expect(Project.find_by_full_path(project_path)).not_to be_nil
      end
    end
  end

  context 'with subgroups', :nested_groups do
    let(:project_path) { 'a-group/a-sub-group/a-project' }

    let(:existing_group) do
      group = create(:group, path: 'a-group')
      create(:group, path: 'a-sub-group', parent: group)
    end

    it_behaves_like 'importing a repository'
  end

  context 'without subgroups' do
    let(:project_path) { 'a-group/a-project' }
    let(:existing_group) { create(:group, path: 'a-group') }

    it_behaves_like 'importing a repository'
  end

  context 'when subgroups are not available' do
    let(:project_path) { 'a-group/a-sub-group/a-project' }

    before do
      expect(Group).to receive(:supports_nested_groups?) { false }
    end

    describe '#create_project_if_needed' do
      it 'raises an error' do
        expect { importer.create_project_if_needed }.to raise_error('Nested groups are not supported on MySQL')
      end
    end
  end
end
