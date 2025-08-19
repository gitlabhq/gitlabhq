# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProcessCommitWorker, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:author) { create(:user) }

  let(:auto_close_issues) { true }
  let(:project) do
    create(:project, :public, :repository, autoclose_referenced_issues: auto_close_issues, developers: author)
  end

  let(:issue) { create(:issue, project: project, author: user) }
  let(:commit) { project.commit }

  let(:worker) { described_class.new }

  it_behaves_like 'worker with data consistency', described_class, {
    data_consistency: :sticky
  }

  it "is deduplicated" do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  end

  context 'with stop signal from database health check' do
    let(:setter) { instance_double(Sidekiq::Job::Setter) }

    around do |example|
      with_sidekiq_server_middleware do |chain|
        chain.add Gitlab::SidekiqMiddleware::SkipJobs
        Sidekiq::Testing.inline! { example.run }
      end
    end

    before do
      stub_feature_flags("drop_sidekiq_jobs_#{described_class.name}": false)

      stop_signal = instance_double(Gitlab::Database::HealthStatus::Signals::Stop, stop?: true)
      allow(Gitlab::Database::HealthStatus).to receive(:evaluate).and_return([stop_signal])
    end

    context 'when the process_commit_worker_deferred feature flag only enabled for some projects' do
      let_it_be(:enabled_project) { create(:project) }

      before do
        stub_feature_flags(process_commit_worker_deferred: [enabled_project])
      end

      it 'defers the job by set time' do
        expect_next_instance_of(described_class) do |worker|
          expect(worker).not_to receive(:perform).with(enabled_project.id, user.id, commit.to_hash, false)
        end

        expect(described_class).to receive(:deferred).and_return(setter)
        expect(setter).to receive(:perform_in).with(described_class::DEFER_ON_HEALTH_DELAY, enabled_project.id, user.id,
          a_kind_of(Hash), false)

        described_class.perform_async(enabled_project.id, user.id, commit.to_hash, false)
      end

      it 'does not defer job execution for other projects' do
        expect_next_instance_of(described_class) do |worker|
          expect(worker).to receive(:perform).with(project.id, user.id, a_kind_of(Hash), false)
        end

        expect(described_class).not_to receive(:perform_in)

        described_class.perform_async(project.id, user.id, commit.to_hash, false)
      end
    end
  end

  describe '#track_time_from_commit_message' do
    let(:issue) { create(:issue, project: project) }
    let(:commit) { project.repository.commit('master') }
    let(:message) { "Fix bug in #{issue.to_reference} @2h" }

    let(:track_time) { -> { worker.send(:track_time_from_commit_message, project, commit, author) } }

    context 'when commit_time_tracking feature flag is disabled' do
      before do
        stub_feature_flags(commit_time_tracking: false)
        allow(commit).to receive(:safe_message).and_return(message)
      end

      it 'does not process time tracking at all' do
        expect(worker).not_to receive(:validate_and_limit_time_tracking_references)
        expect(Gitlab::WorkItems::TimeTrackingExtractor).not_to receive(:new)

        allow(worker).to receive(:track_time_from_commit_message)
        expect(&track_time).not_to change { Timelog.count }
      end
    end

    context 'when commit message has too many issue references (abuse prevention)' do
      let(:issues) { create_list(:issue, ProcessCommitWorker::MAX_TIME_TRACKING_REFERENCES + 1, project: project) }
      let(:message_with_many_issues) do
        issue_refs = issues.map(&:to_reference).join(' ')
        "Fix bugs in #{issue_refs} @2h"
      end

      before do
        allow(commit).to receive(:safe_message).and_return(message_with_many_issues)
        # Mock the validation method to simulate the warning log and return nil
        allow(worker).to receive(:validate_and_limit_time_tracking_references) do |_message, commit, project, user|
          # Simulate the logging behavior
          Gitlab::AppLogger.warn(
            message: "Time tracking abuse prevented: too many issue references",
            issue_count: 6,
            commit_id: commit.id,
            project_id: project.id,
            author_id: commit.author&.id,
            user_id: user.id
          )
          nil
        end
      end

      it 'prevents time tracking when more than 5 issues are referenced' do
        expect(Gitlab::AppLogger).to receive(:warn).with(
          message: "Time tracking abuse prevented: too many issue references",
          issue_count: 6,
          commit_id: commit.id,
          project_id: project.id,
          author_id: commit.author&.id,
          user_id: author.id
        )

        expect(&track_time).not_to change { Timelog.count }
      end

      it 'does not call TimeTrackingExtractor when validation fails' do
        expect(Gitlab::WorkItems::TimeTrackingExtractor).not_to receive(:new)

        track_time.call
      end
    end

    context 'when commit message has exactly 5 issue references (allowed)' do
      let(:issues) { create_list(:issue, ProcessCommitWorker::MAX_TIME_TRACKING_REFERENCES, project: project) }
      let(:message_with_five_issues) do
        issue_refs = issues.map(&:to_reference).join(' ')
        "Fix bugs in #{issue_refs} @2h"
      end

      before do
        allow(commit).to receive(:safe_message).and_return(message_with_five_issues)
        # Mock the validation method to return the message (allowing time tracking to proceed)
        allow(worker).to receive(:validate_and_limit_time_tracking_references).and_return(message_with_five_issues)
      end

      it 'allows time tracking when exactly 5 issues are referenced' do
        expect(Gitlab::AppLogger).not_to receive(:warn)

        # Mock the extractor to return time spent entries for all 5 issues
        allow_next_instance_of(Gitlab::WorkItems::TimeTrackingExtractor) do |instance|
          time_entries = issues.index_with { |_issue| 7200 }
          allow(instance).to receive(:extract_time_spent).and_return(time_entries)
        end

        expect(&track_time).to change { Timelog.count }.by(5)
      end
    end

    context 'when commit message has no time tracking syntax' do
      before do
        allow(commit).to receive(:safe_message).and_return("Fix bug in #{issue.to_reference}")
      end

      it 'skips validation and does not process time tracking' do
        # The validation method is called but returns nil for messages without time tracking syntax
        expect(worker).to receive(:validate_and_limit_time_tracking_references).and_call_original
        expect(Gitlab::WorkItems::TimeTrackingExtractor).not_to receive(:new)

        track_time.call
      end
    end

    context 'when a time entry with the same commit description already exists' do
      before do
        # Create an existing time entry with the same commit description
        description = "#{commit.title} (Commit #{commit.short_id})"
        issue.spend_time(duration: 3600, user_id: author.id, summary: description)
        issue.save!

        # Set up the time tracking extractor to return time spent entries
        allow_next_instance_of(Gitlab::WorkItems::TimeTrackingExtractor) do |instance|
          allow(instance).to receive(:extract_time_spent).and_return({ issue => 7200 })
        end
      end

      it 'does not add duplicate time spent to the issue' do
        expect(&track_time).not_to change { issue.timelogs.count }
      end

      it 'does not create any system notes' do
        expect(&track_time).not_to change { Note.count }
      end
    end

    context 'when commit message contains time tracking information and issue references' do
      before do
        project.repository.create_file(
          user,
          "test-file-#{SecureRandom.hex(4)}.txt",
          "Test content",
          message: message,
          branch_name: 'master'
        )
        # Mock the validation method to return the message (allowing time tracking to proceed)
        allow(worker).to receive(:validate_and_limit_time_tracking_references).and_return(message)
      end

      it 'adds time spent to the referenced issues with commit information as description' do
        expect(&track_time).to change { issue.timelogs.count }.by(1)

        expect(issue.timelogs.last).to have_attributes(
          time_spent: 7200, # 2 hours in seconds
          user: author,
          spent_at: commit.committed_date,
          summary: "#{commit.title} (Commit #{commit.short_id})"
        )
      end

      it 'creates a system note for the time spent' do
        expect(&track_time).to change { Note.count }.by(1)

        note = Note.last
        expect(note.noteable).to eq(issue)
        expect(note.author).to eq(author)
        expect(note.system).to be true
        expect(note.note).to include('added 2h of time spent')
      end

      it 'does not add duplicate time entries when a commit is processed multiple times' do
        # First call adds the time
        expect(&track_time).to change { issue.timelogs.count }.by(1)

        # Second call should not add any additional time entries due to duplicate detection
        expect(&track_time).not_to change { issue.timelogs.count }
      end
    end

    context 'when commit message contains no time tracking information' do
      it 'does not add time spent and system note' do
        expect(&track_time).not_to change { issue.timelogs.count }
        expect(issue.reload.notes.count).to eq(0)
      end
    end

    context 'when referenced issue does not support time tracking' do
      before do
        # Stub the TimeTrackingExtractor to return our issue that doesn't support time tracking
        allow_next_instance_of(Gitlab::WorkItems::TimeTrackingExtractor) do |instance|
          allow(instance).to receive(:extract_time_spent).and_return({ issue => 7200 })
        end

        # Ensure the issue doesn't support time tracking
        allow(issue).to receive(:supports_time_tracking?).and_return(false)
      end

      it 'does not add time spent to the issue' do
        expect(&track_time).not_to change { issue.timelogs.count }
      end

      it 'does not create any system notes' do
        expect(&track_time).not_to change { Note.count }
      end
    end

    context 'when multiple issues are referenced' do
      let(:issue2) { create(:issue, project: project) }
      let(:multi_issue_message) { "Fix bugs in #{issue.to_reference} and #{issue2.to_reference} @3h" }

      before do
        project.repository.create_file(
          user,
          "test-file-#{SecureRandom.hex(4)}.txt",
          "Test content",
          message: multi_issue_message,
          branch_name: 'master'
        )
        # Mock the validation method to return the message (allowing time tracking to proceed)
        allow(worker).to receive(:validate_and_limit_time_tracking_references).and_return(multi_issue_message)
      end

      it 'adds time spent to all referenced issues with commit information as description' do
        expect(&track_time).to change { issue.timelogs.count + issue2.timelogs.count }.by(2)

        expect(issue.timelogs.last).to have_attributes(
          time_spent: 10800, # 3 hours in seconds
          user: author,
          spent_at: commit.committed_date,
          summary: "#{commit.title} (Commit #{commit.short_id})"
        )

        expect(issue2.timelogs.last).to have_attributes(
          time_spent: 10800, # 3 hours in seconds
          user: author,
          spent_at: commit.committed_date,
          summary: "#{commit.title} (Commit #{commit.short_id})"
        )
      end

      it 'creates system notes for all referenced issues' do
        expect(&track_time).to change { Note.count }.by(2)

        [issue, issue2].each do |i|
          note = i.notes.system.last
          expect(note.author).to eq(author)
          expect(note.note).to include('added 3h of time spent')
        end
      end

      context 'when different commits have similar but distinct descriptions' do
        let(:commit2) { project.repository.commit('master~1') }
        let(:commit1_message) { "Fix bug in login #{issue.to_reference} @2h" }
        let(:commit2_message) { "Fix bug in signup #{issue.to_reference} @2h" }

        before do
          # Mock different commits with different short_ids and titles, and include time tracking syntax
          allow(commit).to receive_messages(
            short_id: 'abc123',
            title: 'Fix bug in login',
            safe_message: commit1_message
          )
          allow(commit2).to receive_messages(
            short_id: 'def456',
            title: 'Fix bug in signup',
            safe_message: commit2_message
          )

          # Mock the validation method to return the messages (allowing time tracking to proceed)
          allow(worker).to receive(:validate_and_limit_time_tracking_references).with(commit1_message,
            commit, project,
            author).and_return(commit1_message)
          allow(worker).to receive(:validate_and_limit_time_tracking_references).with(commit2_message,
            commit2, project,
            author).and_return(commit2_message)

          # Set up the time tracking extractor to return time spent entries
          allow_next_instance_of(Gitlab::WorkItems::TimeTrackingExtractor) do |instance|
            allow(instance).to receive(:extract_time_spent).and_return({ issue => 7200 })
          end
        end

        it 'allows time entries for different commits to the same issue' do
          # First commit's time entry
          expect(&track_time).to change { issue.timelogs.count }.by(1)
          expect(issue.timelogs.last.summary).to eq("Fix bug in login (Commit abc123)")

          # Second commit should also be allowed since it has a different description
          worker.send(:track_time_from_commit_message, project, commit2, author)
          expect(issue.timelogs.count).to eq(2)
          expect(issue.timelogs.last.summary).to eq("Fix bug in signup (Commit def456)")
        end
      end

      context 'when issue save fails' do
        let(:invalid_issue) { create(:issue, project: project) }
        let(:invalid_issue_message) { "Fix bug in #{invalid_issue.to_reference} @2h" }

        before do
          # Set up commit message with time tracking syntax
          allow(commit).to receive(:safe_message).and_return(invalid_issue_message)

          # Mock the validation method to return the message (allowing time tracking to proceed)
          allow(worker).to receive(:validate_and_limit_time_tracking_references).and_return(invalid_issue_message)

          # Stub the TimeTrackingExtractor to return our invalid issue
          allow_next_instance_of(Gitlab::WorkItems::TimeTrackingExtractor) do |instance|
            allow(instance).to receive(:extract_time_spent).and_return({ invalid_issue => 7200 })
          end

          # Mock the CreateService to return a failure result
          allow_next_instance_of(Timelogs::CreateService) do |service|
            allow(service).to receive(:execute).and_return(
              ServiceResponse.error(message: 'Failed to save timelog')
            )
          end
        end

        it 'wraps the operation in a transaction' do
          # Execute the method
          track_time.call

          # Verify no time was spent (service handles transaction rollback internally)
          expect(invalid_issue.timelogs.count).to eq(0)
        end
      end

      context 'when SystemNoteService fails to create a note' do
        let(:valid_issue) { create(:issue, project: project) }
        let(:valid_issue_message) { "Fix bug in #{valid_issue.to_reference} @2h" }

        before do
          # Set up commit message with time tracking syntax
          allow(commit).to receive(:safe_message).and_return(valid_issue_message)

          # Mock the validation method to return the message (allowing time tracking to proceed)
          allow(worker).to receive(:validate_and_limit_time_tracking_references).and_return(valid_issue_message)

          allow_next_instance_of(Gitlab::WorkItems::TimeTrackingExtractor) do |instance|
            allow(instance).to receive(:extract_time_spent).and_return({ valid_issue => 7200 })
          end
        end

        context 'when CreateService fails due to timelog save failure' do
          before do
            # Mock the CreateService to return a failure result
            allow_next_instance_of(Timelogs::CreateService) do |service|
              allow(service).to receive(:execute).and_return(
                ServiceResponse.error(message: 'Failed to save timelog')
              )
            end
          end

          it 'logs metadata and an error but does not raise an exception' do
            expect(worker).to receive(:log_hash_metadata_on_done).with(
              issue_id: valid_issue.id,
              project_id: project.id,
              commit_id: commit.id
            )

            expect(Gitlab::AppLogger).to receive(:error).with(
              message: "Failed to create timelog from commit",
              issue_id: valid_issue.id,
              project_id: project.id,
              commit_id: commit.id,
              error_message: 'Failed to save timelog'
            )

            expect { track_time.call }.not_to raise_error
          end

          it 'does not save the time spent to the issue' do
            expect { track_time.call }.not_to change { valid_issue.timelogs.count }
          end
        end

        context 'when CreateService succeeds but SystemNoteService fails internally' do
          it 'still saves the time spent to the issue' do
            expect { track_time.call }.to change { valid_issue.timelogs.count }.by(1)
          end

          it 'does not log any errors in the worker' do
            expect(worker).not_to receive(:log_hash_metadata_on_done)
            expect(Gitlab::AppLogger).not_to receive(:error)

            track_time.call
          end
        end
      end

      context 'when commit author does not have permission to update the items' do
        let_it_be(:inaccessible_project) { create(:project) }

        context 'with issue' do
          let(:other_issue) { create(:issue, project: inaccessible_project) }

          it 'does not add time spent' do
            expect(&track_time).not_to change { other_issue.timelogs.count }
            expect(other_issue.reload.notes.count).to eq(0)
          end
        end

        context 'with work item' do
          let(:other_work_item) { create(:work_item, project: inaccessible_project) }

          it 'does not add time spent' do
            expect(&track_time).not_to change { other_work_item.timelogs.count }
            expect(other_work_item.reload.notes.count).to eq(0)
          end
        end
      end

      context 'when message references issues from a forked project' do
        let(:forked_project) { create(:project, :public, forked_from_project: project) }
        let(:forked_issue) { create(:issue, project: forked_project) }
        let(:message) { "Fix bug in #{forked_issue.to_reference(project)} @2h" }

        before do
          allow(commit).to receive(:safe_message).and_return(message)
          allow(project).to receive(:forked_from?).with(forked_issue.project).and_return(true)

          # Set up the time tracking extractor to return the forked issue
          allow_next_instance_of(Gitlab::WorkItems::TimeTrackingExtractor) do |instance|
            allow(instance).to receive(:extract_time_spent).and_return({ forked_issue => 7200 })
          end
        end

        it 'does not add time spent to issues from forked projects' do
          expect(&track_time).not_to change { forked_issue.timelogs.count }
        end

        it 'does not create system notes for issues from forked projects' do
          expect(&track_time).not_to change { Note.count }
        end
      end
    end

    describe '#validate_and_limit_time_tracking_references' do
      let(:commit) { project.repository.commit('master') }
      let(:validate_method) do
        ->(message) {
          worker.send(:validate_and_limit_time_tracking_references, message, commit, project, user)
        }
      end

      context 'when message is blank' do
        it 'returns nil' do
          expect(validate_method.call('')).to be_nil
          expect(validate_method.call(nil)).to be_nil
        end
      end

      context 'when message has no time tracking syntax' do
        it 'returns nil' do
          message = "Fix bug in #123 and #456"
          expect(validate_method.call(message)).to be_nil
        end
      end

      context 'when message has time tracking but no issue references' do
        it 'returns the original message' do
          message = "General work @2h"
          expect(validate_method.call(message)).to eq(message)
        end
      end

      context 'when message has time tracking with 5 or fewer issue references' do
        it 'returns the original message for exactly 5 references' do
          message = "Fix bugs in #1 #2 #3 #4 #5 @2h"
          expect(validate_method.call(message)).to eq(message)
        end

        it 'returns the original message for fewer than 5 references' do
          message = "Fix bugs in #1 #2 #3 @2h"
          expect(validate_method.call(message)).to eq(message)
        end

        it 'handles cross-project references' do
          message = "Fix bugs in namespace/project#1 other/repo#2 #3 @2h"
          expect(validate_method.call(message)).to eq(message)
        end
      end

      context 'when message has time tracking with more than 5 issue references' do
        let(:message) { "Fix bugs in #1 #2 #3 #4 #5 #6 @2h" }

        before do
          allow(worker).to receive(:user).and_return(user)
        end

        it 'logs a warning and returns nil' do
          expect(Gitlab::AppLogger).to receive(:warn).with(
            message: "Time tracking abuse prevented: too many issue references",
            issue_count: 6,
            commit_id: commit.id,
            project_id: project.id,
            author_id: commit.author&.id,
            user_id: user.id
          )

          expect(validate_method.call(message)).to be_nil
        end

        it 'counts cross-project references' do
          message = "Fix bugs in namespace/project#1 other/repo#2 #3 #4 #5 #6 @2h"

          expect(Gitlab::AppLogger).to receive(:warn).with(
            message: "Time tracking abuse prevented: too many issue references",
            issue_count: 6,
            commit_id: commit.id,
            project_id: project.id,
            author_id: commit.author&.id,
            user_id: user.id
          )

          expect(validate_method.call(message)).to be_nil
        end
      end

      context 'when edge cases' do
        it 'does not count references that are part of URLs' do
          message = "Fix bug https://example.com/#123 and work on #1 @2h"
          expect(validate_method.call(message)).to eq(message)
        end

        it 'handles references at the beginning and end of message' do
          message = "#1 fix bugs in the middle #2 #3 and at the end #4 @2h"
          expect(validate_method.call(message)).to eq(message)
        end

        it 'handles references with punctuation' do
          message = "Fix bugs in #1, #2, #3, #4, and #5. @2h"
          expect(validate_method.call(message)).to eq(message)
        end
      end
    end

    context 'when issue save fails' do
      let(:invalid_issue) { create(:issue, project: project) }
      let(:invalid_issue_message) { "Fix bug in #{invalid_issue.to_reference} @2h" }

      before do
        # Set up commit message with time tracking syntax
        allow(commit).to receive(:safe_message).and_return("Fix bug in #{invalid_issue.to_reference} @2h")

        # Stub the TimeTrackingExtractor to return our invalid issue
        allow_next_instance_of(Gitlab::WorkItems::TimeTrackingExtractor) do |instance|
          allow(instance).to receive(:extract_time_spent).and_return({ invalid_issue => 7200 })
        end

        # Mock the CreateService to return a failure result
        allow_next_instance_of(Timelogs::CreateService) do |service|
          allow(service).to receive(:execute).and_return(
            ServiceResponse.error(message: 'Failed to save timelog')
          )
        end
      end

      it 'wraps the operation in a transaction' do
        # Execute the method
        track_time.call

        # Verify no time was spent (service handles transaction rollback internally)
        expect(invalid_issue.timelogs.count).to eq(0)
      end
    end

    context 'when commit author does not have permission to update the items' do
      let_it_be(:inaccessible_project) { create(:project) }

      context 'with issue' do
        let(:other_issue) { create(:issue, project: inaccessible_project) }

        it 'does not add time spent' do
          expect(&track_time).not_to change { other_issue.timelogs.count }
          expect(other_issue.reload.notes.count).to eq(0)
        end
      end

      context 'with work item' do
        let(:other_work_item) { create(:work_item, project: inaccessible_project) }

        it 'does not add time spent' do
          expect(&track_time).not_to change { other_work_item.timelogs.count }
          expect(other_work_item.reload.notes.count).to eq(0)
        end
      end
    end
  end

  describe '#validate_and_limit_time_tracking_references' do
    let(:commit) { project.repository.commit('master') }
    let(:validate_method) do
      ->(message) {
        worker.send(:validate_and_limit_time_tracking_references, message, commit, project, user)
      }
    end

    context 'when message is blank' do
      it 'returns nil' do
        expect(validate_method.call('')).to be_nil
        expect(validate_method.call(nil)).to be_nil
      end
    end

    context 'when message has no time tracking syntax' do
      it 'returns nil' do
        message = "Fix bug in #123 and #456"
        expect(validate_method.call(message)).to be_nil
      end
    end

    context 'when message has time tracking but no issue references' do
      it 'returns the original message' do
        message = "General work @2h"
        expect(validate_method.call(message)).to eq(message)
      end
    end

    context 'when message has time tracking with 5 or fewer issue references' do
      it 'returns the original message for exactly 5 references' do
        message = "Fix bugs in #1 #2 #3 #4 #5 @2h"
        expect(validate_method.call(message)).to eq(message)
      end

      it 'returns the original message for fewer than 5 references' do
        message = "Fix bugs in #1 #2 #3 @2h"
        expect(validate_method.call(message)).to eq(message)
      end

      it 'handles merge request references' do
        message = "Fix bugs in #1 !2 #3 @2h"
        expect(validate_method.call(message)).to eq(message)
      end

      it 'handles cross-project references' do
        message = "Fix bugs in namespace/project#1 namespace/project!2 #3 @2h"
        expect(validate_method.call(message)).to eq(message)
      end
    end

    context 'when message has time tracking with more than 5 issue references' do
      let(:message) { "Fix bugs in #1 #2 #3 #4 #5 #6 @2h" }

      before do
        allow(worker).to receive(:user).and_return(user)
      end

      it 'logs a warning and returns nil' do
        expect(Gitlab::AppLogger).to receive(:warn).with(
          message: "Time tracking abuse prevented: too many issue references",
          issue_count: 6,
          commit_id: commit.id,
          project_id: project.id,
          author_id: commit.author&.id,
          user_id: user.id
        )

        expect(validate_method.call(message)).to be_nil
      end

      it 'counts mixed issue and merge request references' do
        message = "Fix bugs in #1 !2 #3 !4 #5 !6 #7 @2h"

        expect(validate_method.call(message)).to eq(message)
      end

      it 'counts cross-project references' do
        message = "Fix bugs in namespace/project#1 other/repo#2 #3 #4 #5 #6 @2h"

        expect(Gitlab::AppLogger).to receive(:warn).with(
          message: "Time tracking abuse prevented: too many issue references",
          issue_count: 6,
          commit_id: commit.id,
          project_id: project.id,
          author_id: commit.author&.id,
          user_id: user.id
        )

        expect(validate_method.call(message)).to be_nil
      end
    end

    context 'when edge cases' do
      it 'does not count references that are part of URLs' do
        message = "Fix bug https://example.com/#123 and work on #1 @2h"
        expect(validate_method.call(message)).to eq(message)
      end

      it 'handles references at the beginning and end of message' do
        message = "#1 fix bugs in the middle #2 #3 and at the end #4 @2h"
        expect(validate_method.call(message)).to eq(message)
      end

      it 'handles references with punctuation' do
        message = "Fix bugs in #1, #2, #3, #4, and #5. @2h"
        expect(validate_method.call(message)).to eq(message)
      end
    end
  end

  it 'has a concurrency limit' do
    expect(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap.limit_for(worker: described_class)).to eq(1000)
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
          expect { perform }.to not_change { Issues::CloseWorker.jobs.size }

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
        context 'when commit has work_item reference', :clean_gitlab_redis_cache do
          let(:work_item) { create(:work_item, :task, project: project) }
          let(:work_item_url) { Gitlab::UrlBuilder.build(work_item) }

          before do
            # markdown cache from CacheMarkdownField needs to be cleared otherwise cached references are used
            allow(commit).to receive_messages(
              safe_message: "Ref #{work_item_url}",
              author: author
            )
          end

          it 'creates cross references', :sidekiq_inline do
            expect(work_item_url).to match(%r{/work_items/\d+})

            expect { perform }.to change { Note.count }.by(1)
            created_note = Note.last
            expect(created_note.note).to match(/mentioned in commit/)
          end
        end

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

          it 'passes user_id to CloseWorker' do
            expect { perform }.to change { Issues::CloseWorker.jobs.size }.by(1)

            last_job = Issues::CloseWorker.jobs.last
            expect(last_job['args']).to include(
              project.id,
              issue.id,
              issue.class.to_s,
              hash_including('closed_by' => user.id, 'user_id' => user.id)
            )
          end

          context 'when auto_close_issues_stop_using_commit_author FF is disabled' do
            before do
              stub_feature_flags(auto_close_issues_stop_using_commit_author: false)
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
          end

          it 'creates cross references' do
            expect(commit).to receive(:create_cross_references!).with(user, [issue])

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
          expect(commit).to receive(:create_cross_references!).with(user, [])

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
