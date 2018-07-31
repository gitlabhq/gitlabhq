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
    context 'orphaned project upload file' do
      context 'when an upload record matching the secret and filename is found' do
        context 'when the project is still in legacy storage' do
          let!(:orphaned) { create(:upload, :issuable_upload, :with_file, model: build(:project, :legacy_storage)) }
          let!(:correct_path) { orphaned.absolute_path }
          let!(:other_project) { create(:project, :legacy_storage) }
          let!(:orphaned_path) { correct_path.sub(/#{orphaned.model.full_path}/, other_project.full_path) }

          before do
            FileUtils.mkdir_p(File.dirname(orphaned_path))
            FileUtils.mv(correct_path, orphaned_path)
          end

          it 'moves the file to its proper location' do
            expect(Rails.logger).to receive(:info).twice
            expect(Rails.logger).to receive(:info).with("Did fix #{orphaned_path} -> #{correct_path}")

            expect(File.exist?(orphaned_path)).to be_truthy
            expect(File.exist?(correct_path)).to be_falsey

            stub_env('DRY_RUN', 'false')
            run_rake_task('gitlab:cleanup:project_uploads')

            expect(File.exist?(orphaned_path)).to be_falsey
            expect(File.exist?(correct_path)).to be_truthy
          end

          it 'a dry run does not move the file' do
            expect(Rails.logger).to receive(:info).twice
            expect(Rails.logger).to receive(:info).with("Can fix #{orphaned_path} -> #{correct_path}")
            expect(Rails.logger).to receive(:info)

            expect(File.exist?(orphaned_path)).to be_truthy
            expect(File.exist?(correct_path)).to be_falsey

            run_rake_task('gitlab:cleanup:project_uploads')

            expect(File.exist?(orphaned_path)).to be_truthy
            expect(File.exist?(correct_path)).to be_falsey
          end

          context 'when the project record is missing (Upload#absolute_path raises error)' do
            let!(:lost_and_found_path) { File.join(FileUploader.root, '-', 'project-lost-found', other_project.full_path, orphaned.path) }

            before do
              orphaned.model.delete
            end

            it 'moves the file to lost and found' do
              expect(Rails.logger).to receive(:info).twice
              expect(Rails.logger).to receive(:info).with("Did move to lost and found #{orphaned_path} -> #{lost_and_found_path}")

              expect(File.exist?(orphaned_path)).to be_truthy
              expect(File.exist?(lost_and_found_path)).to be_falsey

              stub_env('DRY_RUN', 'false')
              run_rake_task('gitlab:cleanup:project_uploads')

              expect(File.exist?(orphaned_path)).to be_falsey
              expect(File.exist?(lost_and_found_path)).to be_truthy
            end

            it 'a dry run does not move the file' do
              expect(Rails.logger).to receive(:info).twice
              expect(Rails.logger).to receive(:info).with("Can move to lost and found #{orphaned_path} -> #{lost_and_found_path}")
              expect(Rails.logger).to receive(:info)

              expect(File.exist?(orphaned_path)).to be_truthy
              expect(File.exist?(lost_and_found_path)).to be_falsey

              run_rake_task('gitlab:cleanup:project_uploads')

              expect(File.exist?(orphaned_path)).to be_truthy
              expect(File.exist?(lost_and_found_path)).to be_falsey
            end
          end
        end

        context 'when the project was moved to hashed storage' do
          let!(:orphaned) { create(:upload, :issuable_upload, :with_file) }
          let!(:correct_path) { orphaned.absolute_path }
          let!(:orphaned_path) { File.join(FileUploader.root, 'foo', 'bar', orphaned.path) }

          before do
            FileUtils.mkdir_p(File.dirname(orphaned_path))
            FileUtils.mv(correct_path, orphaned_path)
          end

          it 'moves the file to its proper location' do
            expect(Rails.logger).to receive(:info).twice
            expect(Rails.logger).to receive(:info).with("Did fix #{orphaned_path} -> #{correct_path}")

            expect(File.exist?(orphaned_path)).to be_truthy
            expect(File.exist?(correct_path)).to be_falsey

            stub_env('DRY_RUN', 'false')
            run_rake_task('gitlab:cleanup:project_uploads')

            expect(File.exist?(orphaned_path)).to be_falsey
            expect(File.exist?(correct_path)).to be_truthy
          end

          it 'a dry run does not move the file' do
            expect(Rails.logger).to receive(:info).twice
            expect(Rails.logger).to receive(:info).with("Can fix #{orphaned_path} -> #{correct_path}")
            expect(Rails.logger).to receive(:info)

            expect(File.exist?(orphaned_path)).to be_truthy
            expect(File.exist?(correct_path)).to be_falsey

            run_rake_task('gitlab:cleanup:project_uploads')

            expect(File.exist?(orphaned_path)).to be_truthy
            expect(File.exist?(correct_path)).to be_falsey
          end
        end
      end

      context 'when a matching upload record can not be found' do
        context 'when the file path fits the known pattern' do
          let!(:orphaned) { create(:upload, :issuable_upload, :with_file, model: build(:project, :legacy_storage)) }
          let!(:orphaned_path) { orphaned.absolute_path }
          let!(:lost_and_found_path) { File.join(FileUploader.root, '-', 'project-lost-found', orphaned.model.full_path, orphaned.path) }

          before do
            orphaned.delete
          end

          it 'moves the file to lost and found' do
            expect(Rails.logger).to receive(:info).twice
            expect(Rails.logger).to receive(:info).with("Did move to lost and found #{orphaned_path} -> #{lost_and_found_path}")

            expect(File.exist?(orphaned_path)).to be_truthy
            expect(File.exist?(lost_and_found_path)).to be_falsey

            stub_env('DRY_RUN', 'false')
            run_rake_task('gitlab:cleanup:project_uploads')

            expect(File.exist?(orphaned_path)).to be_falsey
            expect(File.exist?(lost_and_found_path)).to be_truthy
          end

          it 'a dry run does not move the file' do
            expect(Rails.logger).to receive(:info).twice
            expect(Rails.logger).to receive(:info).with("Can move to lost and found #{orphaned_path} -> #{lost_and_found_path}")
            expect(Rails.logger).to receive(:info)

            expect(File.exist?(orphaned_path)).to be_truthy
            expect(File.exist?(lost_and_found_path)).to be_falsey

            run_rake_task('gitlab:cleanup:project_uploads')

            expect(File.exist?(orphaned_path)).to be_truthy
            expect(File.exist?(lost_and_found_path)).to be_falsey
          end
        end

        context 'when the file path does not fit the known pattern' do
          let!(:invalid_path) { File.join('group', 'file.jpg') }
          let!(:orphaned_path) { File.join(FileUploader.root, invalid_path) }
          let!(:lost_and_found_path) { File.join(FileUploader.root, '-', 'project-lost-found', invalid_path) }

          before do
            FileUtils.mkdir_p(File.dirname(orphaned_path))
            FileUtils.touch(orphaned_path)
          end

          after do
            File.delete(orphaned_path) if File.exist?(orphaned_path)
          end

          it 'moves the file to lost and found' do
            expect(Rails.logger).to receive(:info).twice
            expect(Rails.logger).to receive(:info).with("Did move to lost and found #{orphaned_path} -> #{lost_and_found_path}")

            expect(File.exist?(orphaned_path)).to be_truthy
            expect(File.exist?(lost_and_found_path)).to be_falsey

            stub_env('DRY_RUN', 'false')
            run_rake_task('gitlab:cleanup:project_uploads')

            expect(File.exist?(orphaned_path)).to be_falsey
            expect(File.exist?(lost_and_found_path)).to be_truthy
          end

          it 'a dry run does not move the file' do
            expect(Rails.logger).to receive(:info).twice
            expect(Rails.logger).to receive(:info).with("Can move to lost and found #{orphaned_path} -> #{lost_and_found_path}")
            expect(Rails.logger).to receive(:info)

            expect(File.exist?(orphaned_path)).to be_truthy
            expect(File.exist?(lost_and_found_path)).to be_falsey

            run_rake_task('gitlab:cleanup:project_uploads')

            expect(File.exist?(orphaned_path)).to be_truthy
            expect(File.exist?(lost_and_found_path)).to be_falsey
          end
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
      shared_examples_for 'does not move anything' do
        it 'does not move even an orphan file' do
          orphaned = create(:upload, :issuable_upload, :with_file, model: project)
          orphaned_path = orphaned.absolute_path
          orphaned.delete

          expect(File.exist?(orphaned_path)).to be_truthy

          run_rake_task('gitlab:cleanup:project_uploads')

          expect(File.exist?(orphaned_path)).to be_truthy
        end
      end

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

        it_behaves_like 'does not move anything'
      end

      context 'when DRY_RUN env var is unset' do
        let(:project) { create(:project, :legacy_storage) }

        it_behaves_like 'does not move anything'
      end

      context 'when DRY_RUN env var is true' do
        let(:project) { create(:project, :legacy_storage) }

        before do
          stub_env('DRY_RUN', 'true')
        end

        it_behaves_like 'does not move anything'
      end

      context 'when DRY_RUN env var is foo' do
        let(:project) { create(:project, :legacy_storage) }

        before do
          stub_env('DRY_RUN', 'foo')
        end

        it_behaves_like 'does not move anything'
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
