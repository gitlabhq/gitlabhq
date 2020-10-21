# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::SystemNotes::TimeTrackingService do
  let_it_be(:author)   { create(:user) }
  let_it_be(:project)  { create(:project, :repository) }

  describe '#change_due_date' do
    subject { described_class.new(noteable: noteable, project: project, author: author).change_due_date(due_date) }

    let(:due_date) { Date.today }

    context 'when noteable is an issue' do
      let_it_be(:noteable) { create(:issue, project: project) }

      it_behaves_like 'a note with overridable created_at'

      it_behaves_like 'a system note' do
        let(:action) { 'due_date' }
      end

      context 'when due date added' do
        it 'sets the note text' do
          expect(subject.note).to eq "changed due date to #{due_date.to_s(:long)}"
        end
      end

      context 'when due date removed' do
        let(:due_date) { nil }

        it 'sets the note text' do
          expect(subject.note).to eq 'removed due date'
        end
      end

      it 'tracks the issue event in usage ping' do
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_due_date_changed_action).with(author: author)

        subject
      end
    end

    context 'when noteable is a merge request' do
      let_it_be(:noteable) { create(:merge_request, source_project: project) }

      it 'does not track the issue event in usage ping' do
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_due_date_changed_action).with(author: author)

        subject
      end
    end
  end

  describe '#change_time_estimate' do
    subject { described_class.new(noteable: noteable, project: project, author: author).change_time_estimate }

    context 'when noteable is an issue' do
      let_it_be(:noteable, reload: true) { create(:issue, project: project) }

      it_behaves_like 'a system note' do
        let(:action) { 'time_tracking' }
      end

      context 'with a time estimate' do
        it 'sets the note text' do
          noteable.update_attribute(:time_estimate, 277200)

          expect(subject.note).to eq "changed time estimate to 1w 4d 5h"
        end

        context 'when time_tracking_limit_to_hours setting is true' do
          before do
            stub_application_setting(time_tracking_limit_to_hours: true)
          end

          it 'sets the note text' do
            noteable.update_attribute(:time_estimate, 277200)

            expect(subject.note).to eq "changed time estimate to 77h"
          end
        end
      end

      context 'without a time estimate' do
        it 'sets the note text' do
          expect(subject.note).to eq "removed time estimate"
        end
      end

      it 'tracks the issue event in usage ping' do
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_time_estimate_changed_action).with(author: author)

        subject
      end
    end

    context 'when noteable is a merge request' do
      let_it_be(:noteable) { create(:merge_request, source_project: project) }

      it 'does not track the issue event in usage ping' do
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_time_estimate_changed_action).with(author: author)

        subject
      end
    end
  end

  describe '#change_time_spent' do
    subject { described_class.new(noteable: noteable, project: project, author: author).change_time_spent }

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

        it 'tracks the issue event in usage ping' do
          expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_time_spent_changed_action).with(author: author)

          spend_time!(277200)

          subject
        end
      end

      context 'when noteable is a merge request' do
        let_it_be(:noteable) { create(:merge_request, source_project: project) }

        it 'does not track the issue event in usage ping' do
          expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).not_to receive(:track_issue_time_estimate_changed_action).with(author: author)

          spend_time!(277200)

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
