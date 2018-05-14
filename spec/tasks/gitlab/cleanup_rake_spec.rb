require 'rake_helper'

describe 'gitlab:cleanup rake tasks' do
  before do
    Rake.application.rake_require 'tasks/gitlab/cleanup'
  end

  describe 'cleanup' do
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
end
