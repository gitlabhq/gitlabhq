# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProcessCommitWorker, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:author) { create(:user) }

  let(:auto_close_issues) { true }
  let(:project) { create(:project, :public, :repository, autoclose_referenced_issues: auto_close_issues) }
  let(:issue) { create(:issue, project: project, author: user) }
  let(:commit) { project.commit }

  let(:worker) { described_class.new }

  it "is deduplicated" do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
    expect(described_class.get_deduplication_options).to include(feature_flag: :deduplicate_process_commit_worker)
  end

  it 'has a concurrency limit' do
    expect(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap.limit_for(worker: described_class)).to eq(1000)
  end

  context 'when concurrency_limit_process_commit_worker is disabled' do
    before do
      stub_feature_flags(concurrency_limit_process_commit_worker: false)
    end

    it 'does not have a concurrency limit' do
      expect(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap.limit_for(worker: described_class)).to eq(0)
    end
  end

  describe '#perform' do
    subject(:perform) { worker.perform(project_id, user_id, commit.to_hash, default) }

    let(:project_id) { project.id }
    let(:user_id) { user.id }

    before do
      allow(Commit).to receive(:build_from_sidekiq_hash).and_return(commit)
    end

    context 'when pushing to the default branch' do
      let(:default) { true }

      context 'when project does not exist' do
        let(:project_id) { -1 }

        it 'does not close related issues' do
          expect { perform }.to change { Issues::CloseWorker.jobs.size }.by(0)

          perform
        end
      end

      context 'when user does not exist' do
        let(:user_id) { -1 }

        it 'does not close related issues' do
          expect { perform }.not_to change { Issues::CloseWorker.jobs.size }

          perform
        end
      end

      it_behaves_like 'an idempotent worker' do
        before do
          allow(commit).to receive(:safe_message).and_return("Closes #{issue.to_reference}")
          issue.metrics.update!(first_mentioned_in_commit_at: nil)
        end

        subject do
          perform_multiple([project.id, user.id, commit.to_hash], worker: worker)
        end

        it 'closes related issues' do
          expect { perform }.to change { Issues::CloseWorker.jobs.size }.by(1)

          subject
        end
      end

      context 'when commit is not a merge request merge commit' do
        context 'when commit has issue reference' do
          before do
            allow(commit).to receive_messages(
              safe_message: "Closes #{issue.to_reference}",
              author: author
            )
          end

          it 'closes issues that should be closed per the commit message' do
            expect { perform }.to change { Issues::CloseWorker.jobs.size }.by(1)
          end

          it 'passes both author and user_id to CloseWorker' do
            expect { perform }.to change { Issues::CloseWorker.jobs.size }.by(1)

            last_job = Issues::CloseWorker.jobs.last
            expect(last_job['args']).to include(
              project.id,
              issue.id,
              issue.class.to_s,
              hash_including('closed_by' => commit.author.id, 'user_id' => user.id)
            )
          end

          it 'creates cross references' do
            expect(commit).to receive(:create_cross_references!).with(author, [issue])

            perform
          end

          describe 'issue metrics', :clean_gitlab_redis_cache do
            context 'when issue has no first_mentioned_in_commit_at set' do
              before do
                issue.metrics.update!(first_mentioned_in_commit_at: nil)
              end

              it 'updates issue metrics' do
                expect { perform }.to change { issue.metrics.reload.first_mentioned_in_commit_at }
                  .to(commit.committed_date)
              end
            end

            context 'when issue has first_mentioned_in_commit_at earlier than given committed_date' do
              before do
                issue.metrics.update!(first_mentioned_in_commit_at: commit.committed_date - 1.day)
              end

              it "doesn't update issue metrics" do
                expect { perform }.not_to change { issue.metrics.reload.first_mentioned_in_commit_at }
              end
            end

            context 'when issue has first_mentioned_in_commit_at later than given committed_date' do
              before do
                issue.metrics.update!(first_mentioned_in_commit_at: commit.committed_date + 1.day)
              end

              it 'updates issue metrics' do
                expect { perform }.to change { issue.metrics.reload.first_mentioned_in_commit_at }
                  .to(commit.committed_date)
              end
            end
          end

          context 'when project has issue auto close disabled' do
            let(:auto_close_issues) { false }

            it 'does not close related issues' do
              expect { perform }.to not_change { Issues::CloseWorker.jobs.size }
            end

            context 'when issue is an external issue' do
              let(:issue) { ExternalIssue.new('JIRA-123', project) }
              let(:project) do
                create(
                  :project,
                  :with_jira_integration,
                  :public,
                  :repository,
                  autoclose_referenced_issues: auto_close_issues
                )
              end

              it 'closes issues that should be closed per the commit message', :sidekiq_inline do
                expect_next_instance_of(Issues::CloseService) do |close_service|
                  expect(close_service).to receive(:execute).with(issue, commit: commit)
                end

                perform
              end
            end
          end
        end

        context 'when commit has no issue references' do
          before do
            allow(commit).to receive(:safe_message).and_return("Lorem Ipsum")
          end

          describe 'issue metrics' do
            it "doesn't execute any queries with false conditions" do
              expect { perform }.not_to make_queries_matching(/WHERE (?:1=0|0=1)/)
            end
          end
        end
      end

      context 'when commit is a merge request merge commit' do
        let(:merge_request) do
          create(
            :merge_request,
            description: "Closes #{issue.to_reference}",
            source_branch: 'feature-merged',
            target_branch: 'master',
            source_project: project
          )
        end

        let(:commit) do
          project.repository.create_branch('feature-merged', 'feature')
          project.repository.after_create_branch

          MergeRequests::MergeService
            .new(project: project, current_user: merge_request.author, params: { sha: merge_request.diff_head_sha })
            .execute(merge_request)

          merge_request.reload.merge_commit
        end

        it 'does not close any issues from the commit message' do
          expect { perform }.not_to change { Issues::CloseWorker.jobs.size }

          perform
        end

        it 'still creates cross references' do
          expect(commit).to receive(:create_cross_references!).with(commit.author, [])

          perform
        end
      end
    end

    context 'when pushing to a non-default branch' do
      let(:default) { false }

      before do
        allow(commit).to receive(:safe_message).and_return("Closes #{issue.to_reference}")
      end

      it 'does not close any issues from the commit message' do
        expect { perform }.not_to change { Issues::CloseWorker.jobs.size }

        perform
      end

      it 'still creates cross references' do
        expect(commit).to receive(:create_cross_references!).with(user, [])

        perform
      end
    end
  end
end
