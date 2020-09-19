# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UpdatedNotesPaginator do
  let(:issue) { create(:issue) }

  let(:project) { issue.project }
  let(:finder) { NotesFinder.new(user, target: issue, last_fetched_at: last_fetched_at) }
  let(:user) { issue.author }

  let!(:page_1) { create_list(:note, 2, noteable: issue, project: project, updated_at: 2.days.ago) }
  let!(:page_2) { [create(:note, noteable: issue, project: project, updated_at: 1.day.ago)] }

  let(:page_1_boundary) { page_1.last.updated_at + NotesFinder::FETCH_OVERLAP }

  around do |example|
    freeze_time do
      example.run
    end
  end

  before do
    stub_const("Gitlab::UpdatedNotesPaginator::LIMIT", 2)
  end

  subject(:paginator) { described_class.new(finder.execute, last_fetched_at: last_fetched_at) }

  describe 'last_fetched_at: start of time' do
    let(:last_fetched_at) { Time.at(0) }

    it 'calculates the first page of notes', :aggregate_failures do
      expect(paginator.notes).to match_array(page_1)
      expect(paginator.metadata).to match(
        more: true,
        last_fetched_at: microseconds(page_1_boundary)
      )
    end
  end

  describe 'last_fetched_at: start of final page' do
    let(:last_fetched_at) { page_1_boundary }

    it 'calculates a final page', :aggregate_failures do
      expect(paginator.notes).to match_array(page_2)
      expect(paginator.metadata).to match(
        more: false,
        last_fetched_at: microseconds(Time.zone.now)
      )
    end
  end

  # Convert a time to an integer number of microseconds
  def microseconds(time)
    (time.to_i * 1_000_000) + time.usec
  end
end
