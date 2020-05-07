# frozen_string_literal: true

require 'spec_helper'

shared_examples 'a resource event' do
  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }

  let_it_be(:issue1) { create(:issue, author: user1) }
  let_it_be(:issue2) { create(:issue, author: user1) }
  let_it_be(:issue3) { create(:issue, author: user2) }

  describe 'importable' do
    it { is_expected.to respond_to(:importing?) }
    it { is_expected.to respond_to(:imported?) }
  end

  describe 'validations' do
    it { is_expected.not_to allow_value(nil).for(:user) }

    context 'when importing' do
      before do
        allow(subject).to receive(:importing?).and_return(true)
      end

      it { is_expected.to allow_value(nil).for(:user) }
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe '.created_after' do
    let!(:created_at1) { 1.day.ago }
    let!(:created_at2) { 2.days.ago }
    let!(:created_at3) { 3.days.ago }

    let!(:event1) { create(described_class.name.underscore.to_sym, issue: issue1, created_at: created_at1) }
    let!(:event2) { create(described_class.name.underscore.to_sym, issue: issue2, created_at: created_at2) }
    let!(:event3) { create(described_class.name.underscore.to_sym, issue: issue2, created_at: created_at3) }

    it 'returns the expected events' do
      events = described_class.created_after(created_at3)

      expect(events).to contain_exactly(event1, event2)
    end

    it 'returns no events if time is after last record time' do
      events = described_class.created_after(1.minute.ago)

      expect(events).to be_empty
    end
  end
end

shared_examples 'a resource event for issues' do
  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }

  let_it_be(:issue1) { create(:issue, author: user1) }
  let_it_be(:issue2) { create(:issue, author: user1) }
  let_it_be(:issue3) { create(:issue, author: user2) }

  describe 'associations' do
    it { is_expected.to belong_to(:issue) }
  end

  describe '.by_issue' do
    let_it_be(:event1) { create(described_class.name.underscore.to_sym, issue: issue1) }
    let_it_be(:event2) { create(described_class.name.underscore.to_sym, issue: issue2) }
    let_it_be(:event3) { create(described_class.name.underscore.to_sym, issue: issue1) }

    it 'returns the expected records for an issue with events' do
      events = described_class.by_issue(issue1)

      expect(events).to contain_exactly(event1, event3)
    end

    it 'returns the expected records for an issue with no events' do
      events = described_class.by_issue(issue3)

      expect(events).to be_empty
    end
  end

  describe '.by_issue_ids_and_created_at_earlier_or_equal_to' do
    let_it_be(:event1) { create(described_class.name.underscore.to_sym, issue: issue1, created_at: '2020-03-10') }
    let_it_be(:event2) { create(described_class.name.underscore.to_sym, issue: issue2, created_at: '2020-03-10') }
    let_it_be(:event3) { create(described_class.name.underscore.to_sym, issue: issue1, created_at: '2020-03-12') }

    it 'returns the expected records for an issue with events' do
      events = described_class.by_issue_ids_and_created_at_earlier_or_equal_to([issue1.id, issue2.id], '2020-03-11 23:59:59')

      expect(events).to contain_exactly(event1, event2)
    end

    it 'returns the expected records for an issue with no events' do
      events = described_class.by_issue_ids_and_created_at_earlier_or_equal_to(issue3, '2020-03-12')

      expect(events).to be_empty
    end
  end
end

shared_examples 'a resource event for merge requests' do
  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }

  let_it_be(:merge_request1) { create(:merge_request, author: user1) }
  let_it_be(:merge_request2) { create(:merge_request, author: user1) }
  let_it_be(:merge_request3) { create(:merge_request, author: user2) }

  describe 'associations' do
    it { is_expected.to belong_to(:merge_request) }
  end

  describe '.by_merge_request' do
    let_it_be(:event1) { create(described_class.name.underscore.to_sym, merge_request: merge_request1) }
    let_it_be(:event2) { create(described_class.name.underscore.to_sym, merge_request: merge_request2) }
    let_it_be(:event3) { create(described_class.name.underscore.to_sym, merge_request: merge_request1) }

    it 'returns the expected records for an issue with events' do
      events = described_class.by_merge_request(merge_request1)

      expect(events).to contain_exactly(event1, event3)
    end

    it 'returns the expected records for an issue with no events' do
      events = described_class.by_merge_request(merge_request3)

      expect(events).to be_empty
    end
  end
end
