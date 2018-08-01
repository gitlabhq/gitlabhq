require 'rake_helper'

describe 'gitlab:cleanup rake tasks' do
  before do
    Rake.application.rake_require 'tasks/gitlab/cleanup'
  end

  describe 'cleanup namespaces and repos' do
    let(:storages) do
      {
        'default' => Gitlab::GitalyClient::StorageSettings.new(@default_storage_hash.merge('path' => 'tmp/tests/default_storage'))
      }
    end

    before(:all) do
      @default_storage_hash = Gitlab.config.repositories.storages.default.to_h
    end

    before do
      FileUtils.mkdir(Settings.absolute('tmp/tests/default_storage'))
      allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
    end

    after do
      FileUtils.rm_rf(Settings.absolute('tmp/tests/default_storage'))
    end

    describe 'cleanup:repos' do
      before do
        FileUtils.mkdir_p(Settings.absolute('tmp/tests/default_storage/broken/project.git'))
        FileUtils.mkdir_p(Settings.absolute('tmp/tests/default_storage/@hashed/12/34/5678.git'))
      end

      it 'moves it to an orphaned path' do
        run_rake_task('gitlab:cleanup:repos')
        repo_list = Dir['tmp/tests/default_storage/broken/*']

        expect(repo_list.first).to include('+orphaned+')
      end

      it 'ignores @hashed repos' do
        run_rake_task('gitlab:cleanup:repos')

        expect(Dir.exist?(Settings.absolute('tmp/tests/default_storage/@hashed/12/34/5678.git'))).to be_truthy
      end
    end

    describe 'cleanup:dirs' do
      it 'removes missing namespaces' do
        FileUtils.mkdir_p(Settings.absolute("tmp/tests/default_storage/namespace_1/project.git"))
        FileUtils.mkdir_p(Settings.absolute("tmp/tests/default_storage/namespace_2/project.git"))
        allow(Namespace).to receive(:pluck).and_return('namespace_1')

        stub_env('REMOVE', 'true')
        run_rake_task('gitlab:cleanup:dirs')

        expect(Dir.exist?(Settings.absolute('tmp/tests/default_storage/namespace_1'))).to be_truthy
        expect(Dir.exist?(Settings.absolute('tmp/tests/default_storage/namespace_2'))).to be_falsey
      end

      it 'ignores @hashed directory' do
        FileUtils.mkdir_p(Settings.absolute('tmp/tests/default_storage/@hashed/12/34/5678.git'))

        run_rake_task('gitlab:cleanup:dirs')

        expect(Dir.exist?(Settings.absolute('tmp/tests/default_storage/@hashed/12/34/5678.git'))).to be_truthy
      end
    end
  end

  describe 'cleanup:project_uploads' do
    shared_examples_for 'moves the file' do
      context 'with DRY_RUN disabled' do
        before do
          stub_env('DRY_RUN', 'false')
        end

        it 'moves the file to its proper location' do
          expect(File.exist?(path)).to be_truthy
          expect(File.exist?(new_path)).to be_falsey

          run_rake_task('gitlab:cleanup:project_uploads')

          expect(File.exist?(path)).to be_falsey
          expect(File.exist?(new_path)).to be_truthy
        end

        it 'logs action as done' do
          expect(Rails.logger).to receive(:info).twice
          expect(Rails.logger).to receive(:info).with("Did #{action}")

          run_rake_task('gitlab:cleanup:project_uploads')
        end
      end

      shared_examples_for 'does not move the file' do
        it 'does not move the file' do
          expect(File.exist?(path)).to be_truthy
          expect(File.exist?(new_path)).to be_falsey

          run_rake_task('gitlab:cleanup:project_uploads')

          expect(File.exist?(path)).to be_truthy
          expect(File.exist?(new_path)).to be_falsey
        end

        it 'logs action as able to be done' do
          expect(Rails.logger).to receive(:info).twice
          expect(Rails.logger).to receive(:info).with("Can #{action}")
          expect(Rails.logger).to receive(:info).with("\e[33mTo clean up these files run this command with DRY_RUN=false\e[0m")

          run_rake_task('gitlab:cleanup:project_uploads')
        end
      end

      context 'with DRY_RUN explicitly enabled' do
        before do
          stub_env('DRY_RUN', 'true')
        end

        it_behaves_like 'does not move the file'
      end

      context 'with DRY_RUN set to an unknown value' do
        before do
          stub_env('DRY_RUN', 'foo')
        end

        it_behaves_like 'does not move the file'
      end

      context 'with DRY_RUN unset' do
        it_behaves_like 'does not move the file'
      end
    end

    shared_examples_for 'moves the file to lost and found' do
      let(:action) { "move to lost and found #{path} -> #{new_path}" }

      it_behaves_like 'moves the file'
    end

    shared_examples_for 'fixes the file' do
      let(:action) { "fix #{path} -> #{new_path}" }

      it_behaves_like 'moves the file'
    end

    context 'orphaned project upload file' do
      context 'when an upload record matching the secret and filename is found' do
        context 'when the project is still in legacy storage' do
          let(:orphaned) { create(:upload, :issuable_upload, :with_file, model: build(:project, :legacy_storage)) }
          let(:new_path) { orphaned.absolute_path }
          let(:path) { File.join(FileUploader.root, 'some', 'wrong', 'location', orphaned.path) }

          before do
            FileUtils.mkdir_p(File.dirname(path))
            FileUtils.mv(new_path, path)
          end

          it_behaves_like 'fixes the file'
        end

        context 'when the project was moved to hashed storage' do
          let(:orphaned) { create(:upload, :issuable_upload, :with_file) }
          let(:new_path) { orphaned.absolute_path }
          let(:path) { File.join(FileUploader.root, 'some', 'wrong', 'location', orphaned.path) }

          before do
            FileUtils.mkdir_p(File.dirname(path))
            FileUtils.mv(new_path, path)
          end

          it_behaves_like 'fixes the file'
        end

        context 'when the project is missing (Upload#absolute_path raises error)' do
          let(:orphaned) { create(:upload, :issuable_upload, :with_file, model: build(:project, :legacy_storage)) }
          let!(:path) { orphaned.absolute_path }
          let!(:new_path) { File.join(FileUploader.root, '-', 'project-lost-found', orphaned.model.full_path, orphaned.path) }

          before do
            orphaned.model.delete
          end

          it_behaves_like 'moves the file to lost and found'
        end

        context 'when the file should be in object storage' do
          # We will probably want to add logic (Reschedule background upload) to
          # cover Case 2 in https://gitlab.com/gitlab-org/gitlab-ce/issues/46535#note_75355104
          context 'when the file otherwise has the correct local path' do
            let!(:orphaned) { create(:upload, :issuable_upload, :object_storage, model: build(:project, :legacy_storage)) }
            let!(:path) { File.join(FileUploader.root, orphaned.model.full_path, orphaned.path) }

            before do
              stub_feature_flags(import_export_object_storage: true)
              stub_uploads_object_storage(FileUploader)

              FileUtils.mkdir_p(File.dirname(path))
              FileUtils.touch(path)
            end

            it 'does not move the file' do
              expect(File.exist?(path)).to be_truthy

              stub_env('DRY_RUN', 'false')
              run_rake_task('gitlab:cleanup:project_uploads')

              expect(File.exist?(path)).to be_truthy
            end
          end

          # I'm not even sure if this state can or has occurred.
          #
          # This test only serves to define what would happen.
          context 'when the file has the wrong local path' do
            let!(:orphaned) { create(:upload, :issuable_upload, :object_storage, model: build(:project, :legacy_storage)) }
            let!(:path) { File.join(FileUploader.root, 'wrong', orphaned.path) }
            let!(:new_path) { File.join(FileUploader.root, '-', 'project-lost-found', 'wrong', orphaned.path) }

            before do
              stub_feature_flags(import_export_object_storage: true)
              stub_uploads_object_storage(FileUploader)

              FileUtils.mkdir_p(File.dirname(path))
              FileUtils.touch(path)
            end

            it_behaves_like 'moves the file to lost and found'
          end
        end
      end

      context 'when a matching upload record can not be found' do
        context 'when the file path fits the known pattern' do
          let!(:orphaned) { create(:upload, :issuable_upload, :with_file, model: build(:project, :legacy_storage)) }
          let!(:path) { orphaned.absolute_path }
          let!(:new_path) { File.join(FileUploader.root, '-', 'project-lost-found', orphaned.model.full_path, orphaned.path) }

          before do
            orphaned.delete
          end

          it_behaves_like 'moves the file to lost and found'
        end

        context 'when the file path does not fit the known pattern' do
          let!(:invalid_path) { File.join('group', 'file.jpg') }
          let!(:path) { File.join(FileUploader.root, invalid_path) }
          let!(:new_path) { File.join(FileUploader.root, '-', 'project-lost-found', invalid_path) }

          before do
            FileUtils.mkdir_p(File.dirname(path))
            FileUtils.touch(path)
          end

          after do
            File.delete(path) if File.exist?(path)
          end

          it_behaves_like 'moves the file to lost and found'
        end
      end
    end

    context 'non-orphaned project upload file' do
      it 'does not move the file' do
        tracked = create(:upload, :issuable_upload, :with_file, model: build(:project, :legacy_storage))
        tracked_path = tracked.absolute_path

        expect(Rails.logger).not_to receive(:info).with(/move|fix/i)
        expect(File.exist?(tracked_path)).to be_truthy

        stub_env('DRY_RUN', 'false')
        run_rake_task('gitlab:cleanup:project_uploads')

        expect(File.exist?(tracked_path)).to be_truthy
      end
    end

    context 'ignorable cases' do
      # Because we aren't concerned about these, and can save a lot of
      # processing time by ignoring them. If we wish to cleanup hashed storage
      # directories, it should simply require removing this test and modifying
      # the find command.
      context 'when the file is already in hashed storage' do
        let(:project) { create(:project) }

        before do
          stub_env('DRY_RUN', 'false')
          expect(Rails.logger).not_to receive(:info).with(/move|fix/i)
        end

        it 'does not move even an orphan file' do
          orphaned = create(:upload, :issuable_upload, :with_file, model: project)
          path = orphaned.absolute_path
          orphaned.delete

          expect(File.exist?(path)).to be_truthy

          run_rake_task('gitlab:cleanup:project_uploads')

          expect(File.exist?(path)).to be_truthy
        end
      end

      it 'does not move any non-project (FileUploader) uploads' do
        stub_env('DRY_RUN', 'false')

        paths = []
        orphaned1 = create(:upload, :personal_snippet_upload, :with_file)
        orphaned2 = create(:upload, :namespace_upload, :with_file)
        orphaned3 = create(:upload, :attachment_upload, :with_file)
        paths << orphaned1.absolute_path
        paths << orphaned2.absolute_path
        paths << orphaned3.absolute_path
        Upload.delete_all

        expect(Rails.logger).not_to receive(:info).with(/move|fix/i)
        paths.each do |path|
          expect(File.exist?(path)).to be_truthy
        end

        run_rake_task('gitlab:cleanup:project_uploads')

        paths.each do |path|
          expect(File.exist?(path)).to be_truthy
        end
      end

      it 'does not move any uploads in tmp (which would interfere with ongoing upload activity)' do
        stub_env('DRY_RUN', 'false')

        path = File.join(FileUploader.root, 'tmp', 'foo.jpg')
        FileUtils.mkdir_p(File.dirname(path))
        FileUtils.touch(path)

        expect(Rails.logger).not_to receive(:info).with(/move|fix/i)
        expect(File.exist?(path)).to be_truthy

        run_rake_task('gitlab:cleanup:project_uploads')

        expect(File.exist?(path)).to be_truthy
      end
    end
  end
end
