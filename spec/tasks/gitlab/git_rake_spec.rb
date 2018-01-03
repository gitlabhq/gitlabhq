

require 'rake_helper'

describe 'gitlab:git rake tasks' do
  before do
    Rake.application.rake_require 'tasks/gitlab/git'

    storages = { 'default' => { 'path' => Settings.absolute('tmp/tests/default_storage') } }

    FileUtils.mkdir_p(Settings.absolute('tmp/tests/default_storage/@repo/1/2/test.git'))
    allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
    stub_warn_user_is_not_gitlab
  end

  after do
    FileUtils.rm_rf(Settings.absolute('tmp/tests/default_storage'))
  end

  describe 'fsck' do
    it 'outputs the right git command' do
      expect { run_rake_task('gitlab:git:fsck') }.to output(/Performed Checking integrity/).to_stdout
    end
  end
end
