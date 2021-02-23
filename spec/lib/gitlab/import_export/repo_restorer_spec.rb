# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::RepoRestorer do
  include GitHelpers

  let_it_be(:project_with_repo) do
    create(:project, :repository, :wiki_repo, name: 'test-repo-restorer', path: 'test-repo-restorer').tap do |p|
      p.wiki.create_page('page', 'foobar', :markdown, 'created page')
    end
  end

  let!(:project) { create(:project) }

  let(:export_path) { "#{Dir.tmpdir}/project_tree_saver_spec" }
  let(:shared) { project.import_export_shared }

  before do
    allow(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)

    bundler.save
  end

  after do
    FileUtils.rm_rf(export_path)
  end

  describe 'bundle a project Git repo' do
    let(:bundler) { Gitlab::ImportExport::RepoSaver.new(exportable: project_with_repo, shared: shared) }
    let(:bundle_path) { File.join(shared.export_path, Gitlab::ImportExport.project_bundle_filename) }

    subject { described_class.new(path_to_bundle: bundle_path, shared: shared, importable: project) }

    after do
      Gitlab::Shell.new.remove_repository(project.repository_storage, project.disk_path)
    end

    it 'restores the repo successfully' do
      expect(project.repository.exists?).to be false
      expect(subject.restore).to be_truthy

      expect(project.repository.empty?).to be false
    end

    context 'when the repository already exists' do
      it 'deletes the existing repository before importing' do
        allow(project.repository).to receive(:exists?).and_return(true)
        allow(project.repository).to receive(:disk_path).and_return('repository_path')

        expect_next_instance_of(Repositories::DestroyService) do |instance|
          expect(instance).to receive(:execute).and_call_original
        end

        expect(shared.logger).to receive(:info).with(
          message: 'Deleting existing "repository_path" to re-import it.'
        )

        expect(subject.restore).to be_truthy
      end
    end
  end

  describe 'restore a wiki Git repo' do
    let(:bundler) { Gitlab::ImportExport::WikiRepoSaver.new(exportable: project_with_repo, shared: shared) }
    let(:bundle_path) { File.join(shared.export_path, Gitlab::ImportExport.wiki_repo_bundle_filename) }

    subject { described_class.new(path_to_bundle: bundle_path, shared: shared, importable: ProjectWiki.new(project)) }

    after do
      Gitlab::Shell.new.remove_repository(project.wiki.repository_storage, project.wiki.disk_path)
    end

    it 'restores the wiki repo successfully' do
      expect(project.wiki_repository_exists?).to be false

      subject.restore
      project.wiki.repository.expire_status_cache

      expect(project.wiki_repository_exists?).to be true
    end

    describe 'no wiki in the bundle' do
      let!(:project_without_wiki) { create(:project) }

      let(:bundler) { Gitlab::ImportExport::WikiRepoSaver.new(exportable: project_without_wiki, shared: shared) }

      it 'does not creates an empty wiki' do
        expect(subject.restore).to be true
        expect(project.wiki_repository_exists?).to be false
      end
    end
  end
end
