require 'spec_helper'
require 'tasks/gitlab/task_helpers'

class TestHelpersTest
  include Gitlab::TaskHelpers
end

describe Gitlab::TaskHelpers do
  subject { TestHelpersTest.new }

  let(:repo) { 'https://gitlab.com/gitlab-org/gitlab-test.git' }
  let(:clone_path) { Rails.root.join('tmp/tests/task_helpers_tests').to_s }
  let(:version) { '1.1.0' }
  let(:tag) { 'v1.1.0' }

  describe '#checkout_or_clone_version' do
    before do
      allow(subject).to receive(:run_command!)
    end

    it 'checkout the version and reset to it' do
      expect(subject).to receive(:checkout_version).with(tag, clone_path)

      subject.checkout_or_clone_version(version: version, repo: repo, target_dir: clone_path)
    end

    context 'with a branch version' do
      let(:version) { '=branch_name' }
      let(:branch) { 'branch_name' }

      it 'checkout the version and reset to it with a branch name' do
        expect(subject).to receive(:checkout_version).with(branch, clone_path)

        subject.checkout_or_clone_version(version: version, repo: repo, target_dir: clone_path)
      end
    end

    context "target_dir doesn't exist" do
      it 'clones the repo' do
        expect(subject).to receive(:clone_repo).with(repo, clone_path)

        subject.checkout_or_clone_version(version: version, repo: repo, target_dir: clone_path)
      end
    end

    context 'target_dir exists' do
      before do
        expect(Dir).to receive(:exist?).and_return(true)
      end

      it "doesn't clone the repository" do
        expect(subject).not_to receive(:clone_repo)

        subject.checkout_or_clone_version(version: version, repo: repo, target_dir: clone_path)
      end
    end
  end

  describe '#clone_repo' do
    it 'clones the repo in the target dir' do
      expect(subject)
        .to receive(:run_command!).with(%W[#{Gitlab.config.git.bin_path} clone -- #{repo} #{clone_path}])

      subject.clone_repo(repo, clone_path)
    end
  end

  describe '#checkout_version' do
    it 'clones the repo in the target dir' do
      expect(subject)
        .to receive(:run_command!).with(%W[#{Gitlab.config.git.bin_path} -C #{clone_path} fetch --quiet origin #{tag}])
      expect(subject)
        .to receive(:run_command!).with(%W[#{Gitlab.config.git.bin_path} -C #{clone_path} checkout -f --quiet FETCH_HEAD --])

      subject.checkout_version(tag, clone_path)
    end
  end
end
