# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Forks::SyncService, feature_category: :source_code_management do
  include ProjectForksHelper
  include RepoHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:source_project) { create(:project, :repository, :public) }
  let_it_be(:project) { fork_project(source_project, user, { repository: true }) }

  let(:fork_branch) { project.default_branch }
  let(:service) { described_class.new(project, user, fork_branch) }

  def details
    Projects::Forks::Details.new(project, fork_branch)
  end

  def expect_to_cancel_exclusive_lease
    expect(Gitlab::ExclusiveLease).to receive(:cancel)
  end

  describe '#execute' do
    context 'when fork is up-to-date with the upstream' do
      it 'does not perform merge' do
        expect_to_cancel_exclusive_lease
        expect(project.repository).not_to receive(:merge_to_branch)
        expect(project.repository).not_to receive(:ff_merge)

        expect(service.execute).to be_success
      end
    end

    context 'when fork is behind the upstream' do
      let_it_be(:base_commit) { source_project.commit.sha }

      before_all do
        source_project.repository.commit_files(
          user,
          branch_name: source_project.repository.root_ref, message: 'Commit to root ref',
          actions: [{ action: :create, file_path: 'encoding/CHANGELOG', content: 'One more' }]
        )

        source_project.repository.commit_files(
          user,
          branch_name: source_project.repository.root_ref, message: 'Another commit to root ref',
          actions: [{ action: :create, file_path: 'encoding/NEW-CHANGELOG', content: 'One more time' }]
        )
      end

      before do
        project.repository.create_branch(fork_branch, base_commit)
      end

      context 'when fork is not ahead of the upstream' do
        let(:fork_branch) { 'fork-without-new-commits' }

        it 'updates the fork using ff merge' do
          expect_to_cancel_exclusive_lease
          expect(project.commit(fork_branch).sha).to eq(base_commit)
          expect(project.repository).to receive(:ff_merge)
            .with(user, source_project.commit.sha, fork_branch, target_sha: base_commit)
            .and_call_original

          expect do
            expect(service.execute).to be_success
          end.to change { details.counts }.from({ ahead: 0, behind: 2 }).to({ ahead: 0, behind: 0 })
        end
      end

      context 'when fork is ahead of the upstream' do
        context 'and has conflicts with the upstream', :use_clean_rails_redis_caching do
          let(:fork_branch) { 'fork-with-conflicts' }

          it 'returns an error' do
            project.repository.commit_files(
              user,
              branch_name: fork_branch, message: 'Committing something',
              actions: [{ action: :create, file_path: 'encoding/CHANGELOG', content: 'New file' }]
            )

            expect_to_cancel_exclusive_lease
            expect(details).not_to have_conflicts

            expect do
              result = service.execute

              expect(result).to be_error
              expect(result.message).to eq("9:merging commits: merge: there are conflicting files.")
            end.not_to change { details.counts }

            expect(details).to have_conflicts
          end
        end

        context 'and does not have conflicts with the upstream' do
          let(:fork_branch) { 'fork-with-new-commits' }

          it 'updates the fork using merge' do
            project.repository.commit_files(
              user,
              branch_name: fork_branch, message: 'Committing completely new changelog',
              actions: [{ action: :create, file_path: 'encoding/COMPLETELY-NEW-CHANGELOG', content: 'New file' }]
            )

            commit_message = "Merge branch #{source_project.path}:#{source_project.default_branch} into #{fork_branch}"
            expect(project.repository).to receive(:merge_to_branch).with(
              user,
              source_sha: source_project.commit.sha,
              target_branch: fork_branch,
              target_sha: project.commit(fork_branch).sha,
              message: commit_message
            ).and_call_original
            expect_to_cancel_exclusive_lease

            expect do
              expect(service.execute).to be_success
            end.to change { details.counts }.from({ ahead: 1, behind: 2 }).to({ ahead: 2, behind: 0 })

            commits = project.repository.commits_between(source_project.commit.sha, project.commit(fork_branch).sha)
            expect(commits.map(&:message)).to eq([
              "Committing completely new changelog",
              commit_message
            ])
          end
        end
      end

      context 'when a merge cannot happen due to another ongoing merge' do
        it 'does not merge' do
          expect(service).to receive(:perform_merge).and_return(nil)

          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq(described_class::ONGOING_MERGE_ERROR)
        end
      end

      context 'when upstream branch contains lfs reference' do
        let(:source_project) { create(:project, :repository, :public) }
        let(:project) { fork_project(source_project, user, { repository: true }) }
        let(:fork_branch) { 'fork-fetches-lfs-pointers' }

        before do
          source_project.change_head('lfs')

          allow(source_project).to receive(:lfs_enabled?).and_return(true)
          allow(project).to receive(:lfs_enabled?).and_return(true)

          create_file_in_repo(source_project, 'lfs', 'lfs', 'one.lfs', 'One')
          create_file_in_repo(source_project, 'lfs', 'lfs', 'two.lfs', 'Two')
        end

        it 'links fetched lfs objects to the fork project', :aggregate_failures do
          expect_to_cancel_exclusive_lease

          expect do
            expect(service.execute).to be_success
          end.to change { project.reload.lfs_objects.size }.from(0).to(2)
            .and change { details.counts }.from({ ahead: 0, behind: 3 }).to({ ahead: 0, behind: 0 })

          expect(project.lfs_objects).to match_array(source_project.lfs_objects)
        end

        context 'and there are too many of them for a single sync' do
          let(:fork_branch) { 'fork-too-many-lfs-pointers' }

          it 'updates the fork successfully' do
            expect_to_cancel_exclusive_lease
            stub_const('Projects::LfsPointers::LfsLinkService::MAX_OIDS', 1)

            expect do
              result = service.execute

              expect(result).to be_error
              expect(result.message).to eq('Too many LFS object ids to link, please push them manually')
            end.not_to change { details.counts }
          end
        end
      end
    end
  end
end
