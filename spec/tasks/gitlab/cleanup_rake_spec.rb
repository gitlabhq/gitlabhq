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

  # A single integration test that is redundant with one part of the
  # Gitlab::Cleanup::ProjectUploads spec.
  #
  # Additionally, this tests DRY_RUN env var values, and the extra line of
  # output that says you can disable DRY_RUN if it's enabled.
  describe 'cleanup:project_uploads' do
    let!(:logger) { double(:logger) }

    before do
      expect(main_object).to receive(:logger).and_return(logger).at_least(1).times

      allow(logger).to receive(:info).at_least(1).times
      allow(logger).to receive(:debug).at_least(1).times
    end

    context 'with a fixable orphaned project upload file' do
      let(:orphaned) { create(:upload, :issuable_upload, :with_file, model: build(:project, :legacy_storage)) }
      let(:new_path) { orphaned.absolute_path }
      let(:path) { File.join(FileUploader.root, 'some', 'wrong', 'location', orphaned.path) }

      before do
        FileUtils.mkdir_p(File.dirname(path))
        FileUtils.mv(new_path, path)
      end

      context 'with DRY_RUN disabled' do
        before do
          stub_env('DRY_RUN', 'false')
        end

        it 'moves the file to its proper location' do
          run_rake_task('gitlab:cleanup:project_uploads')

          expect(File.exist?(path)).to be_falsey
          expect(File.exist?(new_path)).to be_truthy
        end

        it 'logs action as done' do
          expect(logger).to receive(:info).with("Looking for orphaned project uploads to clean up...")
          expect(logger).to receive(:info).with("Did fix #{path} -> #{new_path}")

          run_rake_task('gitlab:cleanup:project_uploads')
        end
      end

      shared_examples_for 'does not move the file' do
        it 'does not move the file' do
          run_rake_task('gitlab:cleanup:project_uploads')

          expect(File.exist?(path)).to be_truthy
          expect(File.exist?(new_path)).to be_falsey
        end

        it 'logs action as able to be done' do
          expect(logger).to receive(:info).with("Looking for orphaned project uploads to clean up. Dry run...")
          expect(logger).to receive(:info).with("Can fix #{path} -> #{new_path}")
          expect(logger).to receive(:info).with(/To clean up these files run this command with DRY_RUN=false/)

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
  end
end
