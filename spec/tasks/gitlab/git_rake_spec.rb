require 'rake_helper'

describe 'gitlab:git rake tasks' do
  let(:base_path) { 'tmp/tests/default_storage' }

  before(:all) do
    @default_storage_hash = Gitlab.config.repositories.storages.default.to_h
  end

  before do
    Rake.application.rake_require 'tasks/gitlab/git'
    storages = { 'default' => Gitlab::GitalyClient::StorageSettings.new(@default_storage_hash.merge('path' => base_path)) }

    path = Settings.absolute("#{base_path}/@hashed/1/2/test.git")
    FileUtils.mkdir_p(path)
    Gitlab::Popen.popen(%W[git -C #{path} init --bare])

    allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
    allow_any_instance_of(String).to receive(:color) { |string, _color| string }

    stub_warn_user_is_not_gitlab
  end

  after do
    FileUtils.rm_rf(Settings.absolute(base_path))
  end

  describe 'fsck' do
    it 'outputs the integrity check for a repo' do
      expect { run_rake_task('gitlab:git:fsck') }.to output(%r{Performed Checking integrity at .*@hashed/1/2/test.git}).to_stdout
    end

    it 'errors out about config.lock issues' do
      FileUtils.touch(Settings.absolute("#{base_path}/@hashed/1/2/test.git/config.lock"))

      expect { run_rake_task('gitlab:git:fsck') }.to output(/file exists\? ... yes/).to_stdout
    end

    it 'errors out about ref lock issues' do
      FileUtils.mkdir_p(Settings.absolute("#{base_path}/@hashed/1/2/test.git/refs/heads"))
      FileUtils.touch(Settings.absolute("#{base_path}/@hashed/1/2/test.git/refs/heads/blah.lock"))

      expect { run_rake_task('gitlab:git:fsck') }.to output(/Ref lock files exist:/).to_stdout
    end
  end
end
