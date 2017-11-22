require 'rake_helper'

describe 'gitlab:cleanup rake tasks' do
  before do
    Rake.application.rake_require 'tasks/gitlab/cleanup'
  end

  context 'cleanup repositories' do
    let(:gitaly_address) { Gitlab.config.repositories.storages.default.gitaly_address }
    let(:storages) do
      {
        'default' => { 'path' => Settings.absolute('tmp/tests/default_storage'), 'gitaly_address' => gitaly_address  }
      }
    end

    before do
      FileUtils.mkdir(Settings.absolute('tmp/tests/default_storage'))
      allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
    end

    after do
      FileUtils.rm_rf(Settings.absolute('tmp/tests/default_storage'))
    end

    it 'moves it to an orphaned path' do
      FileUtils.mkdir_p(Settings.absolute('tmp/tests/default_storage/broken/project.git'))
      run_rake_task('gitlab:cleanup:repos')
      repo_list = Dir['tmp/tests/default_storage/broken/*']

      expect(repo_list.first).to include('+orphaned+')
    end

    it 'ignores @hashed repos' do
      FileUtils.mkdir_p(Settings.absolute('tmp/tests/default_storage/@hashed/12/34/5678.git'))

      run_rake_task('gitlab:cleanup:repos')

      expect(Dir.exist?(Settings.absolute('tmp/tests/default_storage/@hashed/12/34/5678.git'))).to be_truthy
    end
  end
end
