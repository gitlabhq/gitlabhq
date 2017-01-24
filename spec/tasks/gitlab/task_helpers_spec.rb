require 'spec_helper'
require 'tasks/gitlab/task_helpers'

class TestHelpersTest
  include Gitlab::TaskHelpers
end

describe Gitlab::TaskHelpers do
  subject { TestHelpersTest.new }

  let(:repo) { 'https://gitlab.com/gitlab-org/gitlab-test.git' }
  let(:clone_path) { Rails.root.join('tmp/tests/task_helpers_tests').to_s }
  let(:tag) { 'v1.1.0' }

  describe '#checkout_or_clone_tag' do
    before do
      allow(subject).to receive(:run_command!)
      expect(subject).to receive(:reset_to_tag).with(tag, clone_path)
    end

    context 'target_dir does not exist' do
      it 'clones the repo, retrieve the tag from origin, and checkout the tag' do
        expect(subject).to receive(:clone_repo).with(repo, clone_path)

        subject.checkout_or_clone_tag(tag: tag, repo: repo, target_dir: clone_path)
      end
    end

    context 'target_dir exists' do
      before do
        expect(Dir).to receive(:exist?).and_return(true)
      end

      it 'fetch and checkout the tag' do
        expect(subject).to receive(:checkout_tag).with(tag, clone_path)

        subject.checkout_or_clone_tag(tag: tag, repo: repo, target_dir: clone_path)
      end
    end
  end

  describe '#clone_repo' do
    it 'clones the repo in the target dir' do
      expect(subject).
        to receive(:run_command!).with(%W[#{Gitlab.config.git.bin_path} clone -- #{repo} #{clone_path}])

      subject.clone_repo(repo, clone_path)
    end
  end

  describe '#checkout_tag' do
    it 'clones the repo in the target dir' do
      expect(subject).
        to receive(:run_command!).with(%W[#{Gitlab.config.git.bin_path} -C #{clone_path} fetch --tags --quiet])
      expect(subject).
        to receive(:run_command!).with(%W[#{Gitlab.config.git.bin_path} -C #{clone_path} checkout --quiet #{tag}])

      subject.checkout_tag(tag, clone_path)
    end
  end

  describe '#reset_to_tag' do
    let(:tag) { 'v1.1.0' }
    before do
      expect(subject).
        to receive(:run_command!).with(%W[#{Gitlab.config.git.bin_path} -C #{clone_path} reset --hard #{tag}])
    end

    context 'when the tag is not checked out locally' do
      before do
        expect(subject).
          to receive(:run_command!).with(%W[#{Gitlab.config.git.bin_path} -C #{clone_path} describe -- #{tag}]).and_raise(Gitlab::TaskFailedError)
      end

      it 'fetch origin, ensure the tag exists, and resets --hard to the given tag' do
        expect(subject).
          to receive(:run_command!).with(%W[#{Gitlab.config.git.bin_path} -C #{clone_path} fetch origin])
        expect(subject).
          to receive(:run_command!).with(%W[#{Gitlab.config.git.bin_path} -C #{clone_path} describe -- origin/#{tag}]).and_return(tag)

        subject.reset_to_tag(tag, clone_path)
      end
    end

    context 'when the tag is checked out locally' do
      before do
        expect(subject).
          to receive(:run_command!).with(%W[#{Gitlab.config.git.bin_path} -C #{clone_path} describe -- #{tag}]).and_return(tag)
      end

      it 'resets --hard to the given tag' do
        subject.reset_to_tag(tag, clone_path)
      end
    end
  end
end
