# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Importer do
  let(:user) { create(:user) }
  let(:test_path) { "#{Dir.tmpdir}/importer_spec" }
  let(:shared) { project.import_export_shared }
  let(:import_file) { fixture_file_upload('spec/features/projects/import_export/test_project_export.tar.gz') }
  let(:project) { create(:project, creator: user) }

  subject(:importer) { described_class.new(project) }

  before do
    allow(Gitlab::ImportExport).to receive(:storage_path).and_return(test_path)
    allow_any_instance_of(Gitlab::ImportExport::FileImporter).to receive(:remove_import_file)
    stub_uploads_object_storage(FileUploader)

    FileUtils.mkdir_p(shared.export_path)
    ImportExportUpload.create!(project: project, import_file: import_file, user: user)
    allow(FileUtils).to receive(:rm_rf).and_call_original
  end

  after do
    FileUtils.rm_rf(test_path)
  end

  describe '#execute' do
    it 'succeeds' do
      importer.execute

      expect(shared.errors).to be_empty
    end

    it 'extracts the archive' do
      expect(Gitlab::ImportExport::FileImporter).to receive(:import).and_call_original

      importer.execute
    end

    it 'checks the version' do
      expect(Gitlab::ImportExport::VersionChecker).to receive(:check!).and_call_original

      importer.execute
    end

    context 'all restores are executed' do
      [
        Gitlab::ImportExport::AvatarRestorer,
        Gitlab::ImportExport::RepoRestorer,
        Gitlab::ImportExport::UploadsRestorer,
        Gitlab::ImportExport::LfsRestorer,
        Gitlab::ImportExport::StatisticsRestorer,
        Gitlab::ImportExport::SnippetsRepoRestorer,
        Gitlab::ImportExport::DesignRepoRestorer
      ].each do |restorer|
        it "calls the #{restorer}" do
          fake_restorer = double(restorer.to_s)

          expect(fake_restorer).to receive(:restore).and_return(true).at_least(1)
          expect(restorer).to receive(:new).and_return(fake_restorer).at_least(1)

          importer.execute
        end
      end

      it 'calls RepoRestorer with project and wiki' do
        wiki_repo_path = File.join(shared.export_path, Gitlab::ImportExport.wiki_repo_bundle_filename)
        repo_path = File.join(shared.export_path, Gitlab::ImportExport.project_bundle_filename)
        restorer = double(Gitlab::ImportExport::RepoRestorer)

        expect(Gitlab::ImportExport::RepoRestorer).to receive(:new).with(path_to_bundle: repo_path, shared: shared, importable: project).and_return(restorer)
        expect(Gitlab::ImportExport::RepoRestorer).to receive(:new).with(path_to_bundle: wiki_repo_path, shared: shared, importable: ProjectWiki.new(project)).and_return(restorer)
        expect(Gitlab::ImportExport::RepoRestorer).to receive(:new).and_call_original

        expect(restorer).to receive(:restore).and_return(true).twice

        importer.execute
      end

      context 'with sample_data_template' do
        it 'initializes the Sample::TreeRestorer' do
          project.build_or_assign_import_data(data: { sample_data: true })

          expect(Gitlab::ImportExport::Project::Sample::TreeRestorer).to receive(:new).and_call_original

          importer.execute
        end
      end

      context 'without sample_data_template' do
        it 'initializes the ProjectTree' do
          expect(Gitlab::ImportExport::Project::TreeRestorer).to receive(:new).and_call_original

          importer.execute
        end
      end

      it 'removes the import file' do
        expect(importer).to receive(:remove_import_file).and_call_original

        importer.execute

        expect(project.import_export_upload_by_user(user).import_file&.file).to be_nil
      end

      it 'removes tmp files' do
        importer.execute

        expect(FileUtils).to have_received(:rm_rf).with(shared.base_path)
        expect(Dir.exist?(shared.base_path)).to eq(false)
      end

      it 'sets the correct visibility_level when visibility level is a string' do
        project.build_or_assign_import_data(
          data: { override_params: { visibility_level: Gitlab::VisibilityLevel::PRIVATE.to_s } }
        )

        importer.execute

        expect(project.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
      end
    end

    context 'when import fails' do
      let(:error_message) { 'foo' }

      shared_examples 'removes any non migrated snippet' do
        specify do
          create_list(:project_snippet, 2, project: project)
          snippet_with_repo = create(:project_snippet, :repository, project: project)

          expect { importer.execute }.to change(Snippet, :count).by(-2).and(raise_error(Projects::ImportService::Error))

          expect(snippet_with_repo.reload).to be_present
        end
      end

      context 'when there is a graceful error' do
        before do
          allow_next_instance_of(Gitlab::ImportExport::AvatarRestorer) do |instance|
            allow(instance).to receive(:avatar_export_file).and_raise(StandardError, error_message)
          end
        end

        it 'raises and exception' do
          expect { importer.execute }.to raise_error(Projects::ImportService::Error, error_message)
        end

        it_behaves_like 'removes any non migrated snippet'
      end

      context 'when an unexpected exception is raised' do
        before do
          allow_next_instance_of(Gitlab::ImportExport::AvatarRestorer) do |instance|
            allow(instance).to receive(:restore).and_raise(StandardError, error_message)
          end
        end

        it 'captures it and raises the Projects::ImportService::Error exception' do
          expect { importer.execute }.to raise_error(Projects::ImportService::Error, error_message)
        end

        it_behaves_like 'removes any non migrated snippet'
      end
    end

    context 'when project successfully restored' do
      context "with a project in a user's namespace" do
        let!(:existing_project) { create(:project, namespace: user.namespace) }
        let(:project) { create(:project, namespace: user.namespace, name: 'whatever', path: 'whatever') }

        before do
          restorers = double(:restorers, all?: true)

          allow(subject).to receive(:import_file).and_return(true)
          allow(subject).to receive(:check_version!).and_return(true)
          allow(subject).to receive(:restorers).and_return(restorers)
          allow(project).to receive(:import_data).and_return(double(data: { 'original_path' => existing_project.path }))
        end

        context 'when import_data' do
          context 'has original_path' do
            it 'overwrites existing project' do
              expect_next_instance_of(::Projects::OverwriteProjectService) do |service|
                expect(service).to receive(:execute).with(existing_project)
              end

              subject.execute
            end
          end

          context 'has not original_path' do
            before do
              allow(project).to receive(:import_data).and_return(double(data: {}))
            end

            it 'does not call the overwrite service' do
              expect(::Projects::OverwriteProjectService).not_to receive(:new)

              subject.execute
            end
          end
        end
      end

      context "with a project in a group namespace" do
        let(:group) { create(:group) }
        let!(:existing_project) { create(:project, group: group) }
        let(:project) { create(:project, creator: user, group: group, name: 'whatever', path: 'whatever') }

        before do
          restorers = double(:restorers, all?: true)

          allow(subject).to receive(:import_file).and_return(true)
          allow(subject).to receive(:check_version!).and_return(true)
          allow(subject).to receive(:restorers).and_return(restorers)
          allow(project).to receive(:import_data).and_return(double(data: { 'original_path' => existing_project.path }))
        end

        context 'has original_path' do
          it 'overwrites existing project' do
            group.add_owner(user)

            expect_next_instance_of(::Projects::OverwriteProjectService) do |service|
              expect(service).to receive(:execute).with(existing_project)
            end

            subject.execute
          end

          it 'does not allow user to overwrite existing project' do
            expect(::Projects::OverwriteProjectService).not_to receive(:new)

            expect { subject.execute }.to raise_error(Projects::ImportService::Error,
              "User #{user.username} (#{user.id}) cannot overwrite a project in #{group.path}")
          end
        end
      end
    end
  end
end
