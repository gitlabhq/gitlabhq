# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::Push do
  let_it_be(:project) { create(:project, :repository) }

  let(:oldrev) { project.commit('HEAD~2').id }
  let(:newrev) { project.commit.id }
  let(:ref) { 'refs/heads/some-branch' }

  subject { described_class.new(project, oldrev, newrev, ref) }

  describe '#branch_name' do
    context 'when it is a branch push' do
      let(:ref) { 'refs/heads/my-branch' }

      it 'returns branch name' do
        expect(subject.branch_name).to eq 'my-branch'
      end
    end

    context 'when it is a tag push' do
      let(:ref) { 'refs/tags/my-branch' }

      it 'returns nil' do
        expect(subject.branch_name).to be_nil
      end
    end
  end

  describe '#branch_push?' do
    context 'when pushing a branch ref' do
      let(:ref) { 'refs/heads/my-branch' }

      it { is_expected.to be_branch_push }
    end

    context 'when it is a tag push' do
      let(:ref) { 'refs/tags/my-tag' }

      it { is_expected.not_to be_branch_push }
    end
  end

  describe '#branch_updated?' do
    context 'when it is a branch push with correct old and new revisions' do
      it { is_expected.to be_branch_updated }
    end

    context 'when it is not a branch push' do
      let(:ref) { 'refs/tags/my-tag' }

      it { is_expected.not_to be_branch_updated }
    end

    context 'when old revision is blank' do
      let(:oldrev) { Gitlab::Git::SHA1_BLANK_SHA }

      it { is_expected.not_to be_branch_updated }
    end

    context 'when it is not a branch push' do
      let(:newrev) { Gitlab::Git::SHA1_BLANK_SHA }

      it { is_expected.not_to be_branch_updated }
    end

    context 'when oldrev is nil' do
      let(:oldrev) { nil }

      it { is_expected.not_to be_branch_updated }
    end
  end

  describe '#force_push?' do
    context 'when old revision is an ancestor of the new revision' do
      let(:oldrev) { 'HEAD~3' }
      let(:newrev) { 'HEAD~1' }

      it { is_expected.not_to be_force_push }
    end

    context 'when old revision is not an ancestor of the new revision' do
      let(:oldrev) { 'HEAD~3' }
      let(:newrev) { '123456' }

      it { is_expected.to be_force_push }
    end

    context 'when called mulitiple times' do
      it 'does not make make multiple calls to the force push check' do
        expect(Gitlab::Checks::ForcePush).to receive(:force_push?).once

        2.times do
          subject.force_push?
        end
      end
    end
  end

  describe '#branch_added?' do
    context 'when old revision is defined' do
      it { is_expected.not_to be_branch_added }
    end

    context 'when old revision is not defined' do
      let(:oldrev) { Gitlab::Git::SHA1_BLANK_SHA }

      it { is_expected.to be_branch_added }
    end
  end

  describe '#branch_removed?' do
    context 'when new revision is defined' do
      it { is_expected.not_to be_branch_removed }
    end

    context 'when new revision is not defined' do
      let(:newrev) { Gitlab::Git::SHA1_BLANK_SHA }

      it { is_expected.to be_branch_removed }
    end
  end

  describe '#modified_paths' do
    context 'when a push is a branch update' do
      let(:newrev) { '498214d' }
      let(:oldrev) { '281d3a7' }

      it 'returns modified paths' do
        expect(subject.modified_paths).to eq ['bar/branch-test.txt',
                                              'files/js/commit.coffee',
                                              'with space/README.md']
      end
    end

    context 'when a push is not a branch update' do
      let(:oldrev) { Gitlab::Git::SHA1_BLANK_SHA }

      it 'raises an error' do
        expect { subject.modified_paths }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#changed_paths' do
    context 'when a push is a branch update' do
      let(:newrev) { '498214d' }
      let(:oldrev) { '281d3a7' }

      it 'returns changed paths' do
        expect(subject.changed_paths.as_json).to eq [Gitlab::Git::ChangedPath.new(
          new_blob_id: "93e123ac8a3e6a0b600953d7598af629dec7b735",
          new_mode: "100644",
          old_blob_id: "0000000000000000000000000000000000000000",
          old_mode: "0",
          old_path: "bar/branch-test.txt",
          path: "bar/branch-test.txt",
          status: :ADDED,
          commit_id: ""
        ),
        Gitlab::Git::ChangedPath.new(
          new_blob_id: "85bc2f9753afd5f4fc5d7c75f74f8d526f26b4f3",
          new_mode: "100644",
          old_blob_id: "0000000000000000000000000000000000000000",
          old_mode: "0",
          old_path: "files/js/commit.coffee",
          path: "files/js/commit.coffee",
          status: :ADDED,
          commit_id: ""
        ),
        Gitlab::Git::ChangedPath.new(
          new_blob_id: "0000000000000000000000000000000000000000",
          new_mode: "0",
          old_blob_id: "5f53439ca4b009096571d3c8bc3d09d30e7431b3",
          old_mode: "100644",
          old_path: "files/js/commit.js.coffee",
          path: "files/js/commit.js.coffee",
          status: :DELETED,
          commit_id: ""
        ),
        Gitlab::Git::ChangedPath.new(
          new_blob_id: "8c3014aceae45386c3c026a7ea4a1f68660d51d6",
          new_mode: "100644",
          old_blob_id: "0000000000000000000000000000000000000000",
          old_mode: "0",
          old_path: "with space/README.md",
          path: "with space/README.md",
          status: :ADDED,
          commit_id: ""
        )].as_json
      end
    end

    context 'when a push is not a branch update' do
      let(:oldrev) { Gitlab::Git::SHA1_BLANK_SHA }

      it 'raises an error' do
        expect { subject.changed_paths }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#oldrev' do
    context 'when a valid oldrev is provided' do
      it 'returns oldrev' do
        expect(subject.oldrev).to eq oldrev
      end
    end

    context 'when a nil valud is provided' do
      let(:oldrev) { nil }

      it 'returns blank SHA' do
        expect(subject.oldrev).to eq Gitlab::Git::SHA1_BLANK_SHA
      end
    end
  end

  describe '#newrev' do
    context 'when valid newrev is provided' do
      it 'returns newrev' do
        expect(subject.newrev).to eq newrev
      end
    end

    context 'when a nil valud is provided' do
      let(:newrev) { nil }

      it 'returns blank SHA' do
        expect(subject.newrev).to eq Gitlab::Git::SHA1_BLANK_SHA
      end
    end
  end
end
