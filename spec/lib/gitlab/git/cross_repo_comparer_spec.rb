# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::CrossRepoComparer do
  let(:source_project) { create(:project, :repository) }
  let(:target_project) { create(:project, :repository) }

  let(:source_repo) { source_project.repository.raw_repository }
  let(:target_repo) { target_project.repository.raw_repository }

  let(:source_branch) { 'feature' }
  let(:target_branch) { 'master' }
  let(:straight) { false }

  let(:source_commit) { source_repo.commit(source_branch) }
  let(:target_commit) { source_repo.commit(target_branch) }

  subject(:result) { described_class.new(source_repo, target_repo).compare(source_branch, target_branch, straight: straight) }

  describe '#compare' do
    context 'within a single repository' do
      let(:target_project) { source_project }

      context 'a non-straight comparison' do
        it 'compares without fetching from another repo' do
          expect(source_repo).not_to receive(:fetch_source_branch!)

          expect_compare(result, from: source_commit, to: target_commit)
          expect(result.straight).to eq(false)
        end
      end

      context 'a straight comparison' do
        let(:straight) { true }

        it 'compares without fetching from another repo' do
          expect(source_repo).not_to receive(:fetch_source_branch!)

          expect_compare(result, from: source_commit, to: target_commit)
          expect(result.straight).to eq(true)
        end
      end
    end

    context 'across two repositories' do
      context 'target ref exists in source repo' do
        it 'compares without fetching from another repo' do
          expect(source_repo).not_to receive(:fetch_source_branch!)
          expect(source_repo).not_to receive(:delete_refs)

          expect_compare(result, from: source_commit, to: target_commit)
        end
      end

      context 'target ref does not exist in source repo' do
        it 'compares in the source repo by fetching from the target to a temporary ref' do
          new_commit_id = create_commit(target_project.owner, target_repo, target_branch)
          new_commit = target_repo.commit(new_commit_id)

          # This is how the temporary ref is generated
          expect(SecureRandom).to receive(:hex).at_least(:once).and_return('foo')

          expect(source_repo)
            .to receive(:fetch_source_branch!)
            .with(target_repo, new_commit_id, 'refs/tmp/foo')
            .and_call_original

          expect(source_repo).to receive(:delete_refs).with('refs/tmp/foo').and_call_original

          expect_compare(result, from: source_commit, to: new_commit)
        end
      end

      context 'source ref does not exist in source repo' do
        let(:source_branch) { 'does-not-exist' }

        it 'returns an empty comparison' do
          expect(source_repo).not_to receive(:fetch_source_branch!)
          expect(source_repo).not_to receive(:delete_refs)

          expect(result).to be_a(::Gitlab::Git::Compare)
          expect(result.commits.size).to eq(0)
        end
      end

      context 'target ref does not exist in target repo' do
        let(:target_branch) { 'does-not-exist' }

        it 'returns nil' do
          expect(source_repo).not_to receive(:fetch_source_branch!)
          expect(source_repo).not_to receive(:delete_refs)

          is_expected.to be_nil
        end
      end
    end
  end

  def expect_compare(of, from:, to:)
    expect(of).to be_a(::Gitlab::Git::Compare)
    expect(from).to be_a(::Gitlab::Git::Commit)
    expect(to).to be_a(::Gitlab::Git::Commit)

    expect(of.commits).not_to be_empty
    expect(of.head).to eq(from)
    expect(of.base).to eq(to)
  end

  def create_commit(user, repo, branch)
    action = { action: :create, file_path: '/FILE', content: 'content' }

    result = repo.multi_action(user, branch_name: branch, message: 'Commit', actions: [action])

    result.newrev
  end
end
