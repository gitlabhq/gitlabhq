require 'spec_helper'
require 'rake'

describe 'gitlab:workhorse namespace rake task' do
  before :all do
    Rake.application.rake_require 'tasks/gitlab/task_helpers'

    # empty task as env is already loaded
    Rake::Task.define_task :environment
  end

  describe '#checkout_or_clone_tag' do
    let(:repo) { 'https://gitlab.com/gitlab-org/gitlab-test.git' }
    let(:clone_path) { Rails.root.join('tmp/tests/task_helpers_tests').to_s }
    let(:tag) { 'v1.1.0' }
    before do
      FileUtils.rm_rf(clone_path)
      allow_any_instance_of(Object).to receive(:run_command)
      expect_any_instance_of(Object).to receive(:reset_to_tag).with(tag)
    end

    after do
      FileUtils.rm_rf(clone_path)
    end

    context 'target_dir does not exist' do
      it 'clones the repo, retrieve the tag from origin, and checkout the tag' do
        expect(Dir).to receive(:chdir).and_call_original
        expect_any_instance_of(Object).
          to receive(:run_command).with(%W[#{Gitlab.config.git.bin_path} clone -- #{repo} #{clone_path}]) { FileUtils.mkdir_p(clone_path) } # Fake the cloning

        checkout_or_clone_tag(tag: tag, repo: repo, target_dir: clone_path)
      end
    end

    context 'target_dir exists' do
      before do
        FileUtils.mkdir_p(clone_path)
      end

      it 'fetch and checkout the tag' do
        expect(Dir).to receive(:chdir).twice.and_call_original
        expect_any_instance_of(Object).
          to receive(:run_command).with(%W[#{Gitlab.config.git.bin_path} fetch --tags --quiet])
        expect_any_instance_of(Object).
          to receive(:run_command).with(%W[#{Gitlab.config.git.bin_path} checkout --quiet #{tag}])

        checkout_or_clone_tag(tag: tag, repo: repo, target_dir: clone_path)
      end
    end
  end

  describe '#reset_to_tag' do
    let(:tag) { 'v1.1.0' }
    before do
      expect_any_instance_of(Object).
        to receive(:run_command).with(%W[#{Gitlab.config.git.bin_path} reset --hard #{tag}])
    end

    context 'when the tag is not checked out locally' do
      before do
        expect(Gitlab::Popen).
          to receive(:popen).with(%W[#{Gitlab.config.git.bin_path} describe -- #{tag}]).and_return(['', 42])
      end

      it 'fetch origin, ensure the tag exists, and resets --hard to the given tag' do
        expect_any_instance_of(Object).
          to receive(:run_command).with(%W[#{Gitlab.config.git.bin_path} fetch origin])
        expect_any_instance_of(Object).
          to receive(:run_command).with(%W[#{Gitlab.config.git.bin_path} describe -- origin/#{tag}]).and_return(tag)

        reset_to_tag(tag)
      end
    end

    context 'when the tag is checked out locally' do
      before do
        expect(Gitlab::Popen).
          to receive(:popen).with(%W[#{Gitlab.config.git.bin_path} describe -- #{tag}]).and_return([tag, 0])
      end

      it 'resets --hard to the given tag' do
        reset_to_tag(tag)
      end
    end
  end
end
