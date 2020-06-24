# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::SystemNotes::TimeTrackingService do
  let_it_be(:author)   { create(:user) }
  let_it_be(:project)  { create(:project, :repository) }

  let(:noteable) { create(:issue, project: project) }

  describe '#change_due_date' do
    subject { described_class.new(noteable: noteable, project: project, author: author).change_due_date(due_date) }

    let(:due_date) { Date.today }

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
  end

  describe '.change_time_estimate' do
    subject { described_class.new(noteable: noteable, project: project, author: author).change_time_estimate }

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
  end

  describe '.change_time_spent' do
    # We need a custom noteable in order to the shared examples to be green.
    let(:noteable) do
      mr = create(:merge_request, source_project: project)
      mr.spend_time(duration: 360000, user_id: author.id)
      mr.save!
      mr
    end

    subject do
      described_class.new(noteable: noteable, project: project, author: author).change_time_spent
    end

    it_behaves_like 'a system note' do
      let(:action) { 'time_tracking' }
    end

    context 'when time was added' do
      it 'sets the note text' do
        spend_time!(277200)

        expect(subject.note).to eq "added 1w 4d 5h of time spent"
      end
    end

    context 'when time was subtracted' do
      it 'sets the note text' do
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

    def spend_time!(seconds)
      noteable.spend_time(duration: seconds, user_id: author.id)
      noteable.save!
    end
  end
end
