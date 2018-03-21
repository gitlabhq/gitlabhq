require 'rake_helper'

describe 'gitlab:git rake tasks' do
  before do
    Rake.application.rake_require 'tasks/gitlab/git'

    storages = { 'default' => { 'path' => Settings.absolute('tmp/tests/default_storage') } }

    FileUtils.mkdir_p(Settings.absolute('tmp/tests/default_storage/@hashed/1/2/test.git'))
    allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
    allow_any_instance_of(String).to receive(:color) { |string, _color| string }

    stub_warn_user_is_not_gitlab
  end

  after do
    FileUtils.rm_rf(Settings.absolute('tmp/tests/default_storage'))
  end

  describe 'fsck' do
    it 'outputs the integrity check for a repo' do
      expect { run_rake_task('gitlab:git:fsck') }.to output(%r{Performed Checking integrity at .*@hashed/1/2/test.git}).to_stdout
    end

    it 'errors out about config.lock issues' do
      FileUtils.touch(Settings.absolute('tmp/tests/default_storage/@hashed/1/2/test.git/config.lock'))

      expect { run_rake_task('gitlab:git:fsck') }.to output(/file exists\? ... yes/).to_stdout
    end

    it 'errors out about ref lock issues' do
      FileUtils.mkdir_p(Settings.absolute('tmp/tests/default_storage/@hashed/1/2/test.git/refs/heads'))
      FileUtils.touch(Settings.absolute('tmp/tests/default_storage/@hashed/1/2/test.git/refs/heads/blah.lock'))

      expect { run_rake_task('gitlab:git:fsck') }.to output(/Ref lock files exist:/).to_stdout
    end
  end
end
