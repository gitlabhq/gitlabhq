# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::SystemNotes::TimeTrackingService, feature_category: :team_planning do
  let_it_be(:author)  { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  describe '#change_start_date_or_due_date' do
    let_it_be(:issue)     { create(:issue, project: project) }
    let_it_be(:work_item) { create(:work_item, project: project) }

    subject(:note) { described_class.new(noteable: noteable, container: project, author: author).change_start_date_or_due_date(changed_dates) }

    let(:start_date) { Date.today }
    let(:due_date) { 1.week.from_now.to_date }
    let(:changed_dates) { { 'due_date' => [nil, due_date], 'start_date' => [nil, start_date] } }

    shared_examples 'issuable getting date change notes' do
      it_behaves_like 'a note with overridable created_at'

      it_behaves_like 'a system note' do
        let(:action) { 'start_date_or_due_date' }
      end

      context 'when both dates are added' do
        it 'sets the correct note message' do
          expect(note.note).to eq("changed start date to #{start_date.to_fs(:long)} and changed due date to #{due_date.to_fs(:long)}")
        end
      end

      context 'when both dates are removed' do
        let(:changed_dates) { { 'due_date' => [due_date, nil], 'start_date' => [start_date, nil] } }

        before do
          noteable.update!(start_date: start_date, due_date: due_date)
        end

        it 'sets the correct note message' do
          expect(note.note).to eq("removed start date #{start_date.to_fs(:long)} and removed due date #{due_date.to_fs(:long)}")
        end
      end

      context 'when due date is added' do
        let(:changed_dates) { { 'due_date' => [nil, due_date] } }

        it 'sets the correct note message' do
          expect(note.note).to eq("changed due date to #{due_date.to_fs(:long)}")
        end

        context 'and start date removed' do
          let(:changed_dates) { { 'due_date' => [nil, due_date], 'start_date' => [start_date, nil] } }

          it 'sets the correct note message' do
            expect(note.note).to eq("removed start date #{start_date.to_fs(:long)} and changed due date to #{due_date.to_fs(:long)}")
          end
        end
      end

      context 'when start_date is added' do
        let(:changed_dates) { { 'start_date' => [nil, start_date] } }

        it 'does not track the issue event' do
          expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_due_date_changed_action)

          subject
        end

        it 'does not emit snowplow event', :snowplow do
          expect_no_snowplow_event

          subject
        end

        it 'sets the correct note message' do
          expect(note.note).to eq("changed start date to #{start_date.to_fs(:long)}")
        end

        context 'and due date removed' do
          let(:changed_dates) { { 'due_date' => [due_date, nil], 'start_date' => [nil, start_date] } }

          it 'sets the correct note message' do
            expect(note.note).to eq("changed start date to #{start_date.to_fs(:long)} and removed due date #{due_date.to_fs(:long)}")
          end
        end
      end

      context 'when no dates are changed' do
        let(:changed_dates) { {} }

        it 'does not create a note and returns nil' do
          expect do
            note
          end.to not_change(Note, :count)

          expect(note).to be_nil
        end
      end
    end

    context 'when noteable is an issue' do
      let(:noteable) { issue }
      let(:activity_counter_class) { Gitlab::UsageDataCounters::IssueActivityUniqueCounter }
      let(:activity_counter_method) { :track_issue_due_date_changed_action }

      it_behaves_like 'issuable getting date change notes'

      it 'does not track the work item event in usage ping' do
        expect(Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter).not_to receive(:track_work_item_date_changed_action)

        subject
      end

      it 'tracks the issue event' do
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_due_date_changed_action)
                                                                           .with(author: author, project: project)

        subject
      end

      it_behaves_like 'internal event tracking' do
        let(:event) { Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_DUE_DATE_CHANGED }
        let(:user) { author }
        let(:namespace) { project.namespace }
      end

      context 'when only start_date is added' do
        let(:changed_dates) { { 'start_date' => [nil, start_date] } }

        it 'does not track the issue event in usage ping' do
          expect(activity_counter_class).not_to receive(activity_counter_method)

          subject
        end
      end
    end

    context 'when noteable is a work item' do
      let(:noteable) { work_item }
      let(:activity_counter_class) { Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter }
      let(:activity_counter_method) { :track_work_item_date_changed_action }

      it_behaves_like 'issuable getting date change notes'

      it 'does not track the issue event' do
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_due_date_changed_action)

        subject
      end

      it 'does not emit snowplow event', :snowplow do
        expect_no_snowplow_event

        subject
      end

      context 'when only start_date is added' do
        let(:changed_dates) { { 'start_date' => [nil, start_date] } }

        it 'tracks the issue event in usage ping' do
          expect(activity_counter_class).to receive(activity_counter_method).with(author: author)

          subject
        end
      end
    end

    context 'when noteable is a merge request' do
      let(:noteable) { create(:merge_request, source_project: project) }

      it 'does not track the issue event' do
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_due_date_changed_action)

        subject
      end

      it 'does not track the work item event in usage ping' do
        expect(Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter).not_to receive(:track_work_item_date_changed_action)

        subject
      end

      it 'does not emit snowplow event', :snowplow do
        expect_no_snowplow_event

        subject
      end
    end
  end

  describe '#change_time_estimate' do
    subject { described_class.new(noteable: noteable, container: project, author: author).change_time_estimate }

    context 'when noteable is an issue' do
      let_it_be(:noteable, reload: true) { create(:issue, project: project) }

      it_behaves_like 'a system note' do
        let(:action) { 'time_tracking' }
      end

      context 'when adding a time estimate' do
        before do
          noteable.update_attribute(:time_estimate, 277200)
        end

        it 'sets the note text' do
          expect(subject.note).to eq "added time estimate of 1w 4d 5h"
        end

        context 'when time_tracking_limit_to_hours setting is true' do
          before do
            stub_application_setting(time_tracking_limit_to_hours: true)
          end

          it 'sets the note text' do
            expect(subject.note).to eq "added time estimate of 77h"
          end
        end
      end

      context 'when removing a time estimate' do
        before do
          noteable.update_attribute(:time_estimate, 277200)
          noteable.save!
          noteable.update_attribute(:time_estimate, 0)
        end

        it 'sets the note text' do
          expect(subject.note).to eq "removed time estimate of 1w 4d 5h"
        end
      end

      context 'when changing a time estimate' do
        before do
          noteable.update_attribute(:time_estimate, 277200)
          noteable.save!
          noteable.update_attribute(:time_estimate, 3600)
        end

        it 'sets the note text' do
          expect(subject.note).to eq "changed time estimate to 1h from 1w 4d 5h"
        end
      end

      it 'tracks the issue event in usage ping' do
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_time_estimate_changed_action)
                                                                           .with(author: author, project: project)

        subject
      end

      it_behaves_like 'internal event tracking' do
        let(:event) { Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_TIME_ESTIMATE_CHANGED }
        let(:user) { author }
        let(:namespace) { project.namespace }
      end
    end

    context 'when noteable is a merge request' do
      let_it_be(:noteable) { create(:merge_request, source_project: project) }

      it 'does not track the issue event' do
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_time_estimate_changed_action)
                                                                               .with(author: author, project: project)

        subject
      end

      it 'does not emit snowplow event', :snowplow do
        expect_no_snowplow_event

        subject
      end
    end
  end

  describe '#create_timelog' do
    subject { described_class.new(noteable: noteable, container: project, author: author).created_timelog(timelog) }

    context 'when the timelog has a positive time spent value' do
      let_it_be(:noteable, reload: true) { create(:issue, project: project) }

      let(:timelog) { create(:timelog, user: author, issue: noteable, time_spent: 1800, spent_at: '2022-03-30T00:00:00.000Z') }

      it 'sets the note text' do
        expect(subject.note).to eq "added 30m of time spent at 2022-03-30"
      end
    end

    context 'when the timelog has a negative time spent value' do
      let_it_be(:noteable, reload: true) { create(:issue, project: project) }

      let!(:existing_timelog) { create(:timelog, user: author, issue: noteable, time_spent: time_spent.to_i) }

      let(:time_spent) { 1800.seconds }
      let(:spent_at) { '2022-03-30T00:00:00.000Z' }
      let(:timelog) { create(:timelog, user: author, issue: noteable, time_spent: -time_spent.to_i, spent_at: spent_at) }

      it 'sets the note text' do
        expect(subject.note).to eq "subtracted 30m of time spent at 2022-03-30"
      end
    end
  end

  describe '#remove_timelog' do
    subject { described_class.new(noteable: noteable, container: project, author: author).remove_timelog(timelog) }

    context 'when the timelog has a positive time spent value' do
      let_it_be(:noteable, reload: true) { create(:issue, project: project) }

      let(:timelog) { create(:timelog, user: author, issue: noteable, time_spent: 1800, spent_at: '2022-03-30T00:00:00.000Z') }

      it 'sets the note text' do
        expect(subject.note).to eq "deleted 30m of spent time from 2022-03-30"
      end
    end

    context 'when the timelog has a negative time spent value' do
      let_it_be(:noteable, reload: true) { create(:issue, project: project) }

      let!(:existing_timelog) { create(:timelog, user: author, issue: noteable, time_spent: time_spent.to_i) }

      let(:time_spent) { 1800.seconds }
      let(:spent_at) { '2022-03-30T00:00:00.000Z' }
      let(:timelog) { create(:timelog, user: author, issue: noteable, time_spent: -time_spent.to_i, spent_at: spent_at) }

      it 'sets the note text' do
        expect(subject.note).to eq "deleted -30m of spent time from 2022-03-30"
      end
    end
  end

  describe '#change_time_spent' do
    subject { described_class.new(noteable: noteable, container: project, author: author).change_time_spent }

    context 'when noteable is an issue' do
      let_it_be(:noteable, reload: true) { create(:issue, project: project) }

      it_behaves_like 'a system note' do
        let(:action) { 'time_tracking' }

        before do
          spend_time!(277200)
        end
      end

      context 'when time was added' do
        it 'sets the note text' do
          spend_time!(277200)

          expect(subject.note).to eq "added 1w 4d 5h of time spent"
        end

        context 'when time was subtracted' do
          it 'sets the note text' do
            spend_time!(360000)
            spend_time!(-277200)

            expect(subject.note).to eq "subtracted 1w 4d 5h of time spent"
          end
        end

        context 'when time was removed' do
          it 'sets the note text' do
            spend_time!(:reset)

            expect(subject.note).to eq "removed time spent"
          end
        end

        context 'when time_tracking_limit_to_hours setting is true' do
          before do
            stub_application_setting(time_tracking_limit_to_hours: true)
          end

          it 'sets the note text' do
            spend_time!(277200)

            expect(subject.note).to eq "added 77h of time spent"
          end
        end

        it 'tracks the issue event' do
          expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_time_spent_changed_action)
                                                                             .with(author: author, project: project)

          spend_time!(277200)

          subject
        end

        it_behaves_like 'internal event tracking' do
          let(:event) { Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_TIME_SPENT_CHANGED }
          let(:user) { author }
          let(:namespace) { project.namespace }

          before do
            spend_time!(277200)
          end
        end
      end

      context 'when noteable is a merge request' do
        let_it_be(:noteable) { create(:merge_request, source_project: project) }

        it 'does not track the issue event' do
          expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_time_estimate_changed_action)
                                                                                 .with(author: author, project: project)

          spend_time!(277200)

          subject
        end

        it 'does not emit snowplow event', :snowplow do
          expect_no_snowplow_event

          subject
        end
      end

      def spend_time!(seconds)
        noteable.spend_time(duration: seconds, user_id: author.id)
        noteable.save!
      end
    end
  end
end
