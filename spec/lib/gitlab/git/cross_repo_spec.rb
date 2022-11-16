# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::CrossRepo do
  let_it_be(:source_project) { create(:project, :repository) }
  let_it_be(:target_project) { create(:project, :repository) }

  let(:source_repo) { source_project.repository.raw_repository }
  let(:target_repo) { target_project.repository.raw_repository }

  let(:source_branch) { 'feature' }
  let(:target_branch) { target_repo.root_ref }

  let(:source_commit) { source_repo.commit(source_branch) }
  let(:target_commit) { source_repo.commit(target_branch) }

  def execute(&block)
    described_class.new(source_repo, target_repo).execute(target_branch, &block)
  end

  describe '#execute' do
    context 'when executed within a single repository' do
      let(:target_project) { source_project }

      it 'does not fetch from another repo' do
        expect(source_repo).not_to receive(:fetch_source_branch!)

        expect { |block| execute(&block) }.to yield_with_args(target_branch)
      end
    end

    context 'when executed across two repositories' do
      context 'and target ref exists in source repo' do
        it 'does not fetch from another repo' do
          expect(source_repo).not_to receive(:fetch_source_branch!)
          expect(source_repo).not_to receive(:delete_refs)

          expect { |block| execute(&block) }.to yield_with_args(target_commit.id)
        end
      end

      context 'and target ref does not exist in source repo' do
        let_it_be(:target_project) { create(:project, :repository) }

        it 'fetches from the target to a temporary ref' do
          new_commit_id = create_commit(target_project.owner, target_repo, target_branch)

          # This is how the temporary ref is generated
          expect(SecureRandom).to receive(:hex).at_least(:once).and_return('foo')

          expect(source_repo)
            .to receive(:fetch_source_branch!)
            .with(target_repo, new_commit_id, 'refs/tmp/foo')
            .and_call_original

          expect(source_repo).to receive(:delete_refs).with('refs/tmp/foo').and_call_original

          expect { |block| execute(&block) }.to yield_with_args(new_commit_id)
        end
      end

      context 'and target ref does not exist in target repo' do
        let(:target_branch) { 'does-not-exist' }

        it 'returns nil' do
          expect(source_repo).not_to receive(:fetch_source_branch!)
          expect(source_repo).not_to receive(:delete_refs)

          expect { |block| execute(&block) }.not_to yield_control
        end
      end
    end
  end

  def create_commit(user, repo, branch)
    action = { action: :create, file_path: '/FILE', content: 'content' }

    result = repo.commit_files(user, branch_name: branch, message: 'Commit', actions: [action])

    result.newrev
  end
end
