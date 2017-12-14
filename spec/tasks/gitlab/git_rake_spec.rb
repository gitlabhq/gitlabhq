require 'rake_helper'

describe 'gitlab:git rake tasks' do
  before do
    Rake.application.rake_require 'tasks/gitlab/git'

    stub_warn_user_is_not_gitlab

    FileUtils.mkdir(Settings.absolute('tmp/tests/default_storage'))
  end

  after do
    FileUtils.rm_rf(Settings.absolute('tmp/tests/default_storage'))
  end

  describe 'fsck' do
    let(:storages) do
      { 'default' => { 'path' => Settings.absolute('tmp/tests/default_storage') } }
    end

    it 'outputs the right git command' do
      expect(Kernel).to receive(:system).with('').and_return(true)

      run_rake_task('gitlab:git:fsck')
    end
  end
end
