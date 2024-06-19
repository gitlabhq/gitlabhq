# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'a resource event' do
  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }

  let_it_be(:issue1) { create(:issue, author: user1) }
  let_it_be(:issue2) { create(:issue, author: user1) }
  let_it_be(:issue3) { create(:issue, author: user2) }

  let(:resource_event) { described_class.name.demodulize.underscore.to_sym }

  describe 'importable' do
    it { is_expected.to respond_to(:importing?) }
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

    let!(:event1) { create(resource_event, issue: issue1, created_at: created_at1) }
    let!(:event2) { create(resource_event, issue: issue2, created_at: created_at2) }
    let!(:event3) { create(resource_event, issue: issue2, created_at: created_at3) }

    it 'returns the expected events' do
      events = described_class.created_after(created_at3)

      expect(events).to contain_exactly(event1, event2)
    end

    it 'returns no events if time is after last record time' do
      events = described_class.created_after(1.minute.ago)

      expect(events).to be_empty
    end
  end

  describe '#synthetic_note_class' do
    it 'must implement #synthetic_note_class method' do
      expect { described_class.new.synthetic_note_class }
        .not_to raise_error
    end
  end
end

RSpec.shared_examples 'a resource event that responds to imported' do
  describe 'import source' do
    it { is_expected.to respond_to(:imported?) }
    it { is_expected.to respond_to(:imported_from) }
  end
end

RSpec.shared_examples 'a resource event for issues' do
  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }

  let_it_be(:issue1) { create(:issue, author: user1) }
  let_it_be(:issue2) { create(:issue, author: user1) }
  let_it_be(:issue3) { create(:issue, author: user2) }

  let_it_be(:resource_event) { described_class.name.demodulize.underscore.to_sym }
  let_it_be(:event1) { create(resource_event, issue: issue1) }
  let_it_be(:event2) { create(resource_event, issue: issue2) }
  let_it_be(:event3) { create(resource_event, issue: issue1) }

  describe 'associations' do
    it { is_expected.to belong_to(:issue) }
  end

  describe '.by_issue' do
    it 'returns the expected records for an issue with events' do
      events = described_class.by_issue(issue1)

      expect(events).to contain_exactly(event1, event3)
    end

    it 'returns the expected records for an issue with no events' do
      events = described_class.by_issue(issue3)

      expect(events).to be_empty
    end
  end

  describe '.by_issue_ids' do
    it 'returns the expected events' do
      events = described_class.by_issue_ids([issue1.id])

      expect(events).to contain_exactly(event1, event3)
    end
  end

  describe '.by_created_at_earlier_or_equal_to' do
    let_it_be(:event1) { create(resource_event, issue: issue1, created_at: '2020-03-10') }
    let_it_be(:event2) { create(resource_event, issue: issue2, created_at: '2020-03-10') }
    let_it_be(:event3) { create(resource_event, issue: issue1, created_at: '2020-03-12') }

    it 'returns the expected events' do
      events = described_class.by_created_at_earlier_or_equal_to('2020-03-11 23:59:59')

      expect(events).to contain_exactly(event1, event2)
    end

    it 'returns the expected events' do
      events = described_class.by_created_at_earlier_or_equal_to('2020-03-12')

      expect(events).to contain_exactly(event1, event2, event3)
    end
  end

  if described_class.method_defined?(:issuable)
    describe '#issuable' do
      let_it_be(:event1) { create(resource_event, issue: issue2) }

      it 'returns the expected issuable' do
        expect(event1.issuable).to eq(issue2)
      end
    end
  end
end

RSpec.shared_examples 'a resource event for merge requests' do
  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }

  let_it_be(:resource_event) { described_class.name.demodulize.underscore.to_sym }
  let_it_be(:merge_request1) { create(:merge_request, author: user1) }
  let_it_be(:merge_request2) { create(:merge_request, author: user1) }
  let_it_be(:merge_request3) { create(:merge_request, author: user2) }

  describe 'associations' do
    it { is_expected.to belong_to(:merge_request) }
  end

  describe '.by_merge_request' do
    let_it_be(:event1) { create(resource_event, merge_request: merge_request1) }
    let_it_be(:event2) { create(resource_event, merge_request: merge_request2) }
    let_it_be(:event3) { create(resource_event, merge_request: merge_request1) }

    it 'returns the expected records for an issue with events' do
      events = described_class.by_merge_request(merge_request1)

      expect(events).to contain_exactly(event1, event3)
    end

    it 'returns the expected records for an issue with no events' do
      events = described_class.by_merge_request(merge_request3)

      expect(events).to be_empty
    end
  end

  if described_class.method_defined?(:issuable)
    describe '#issuable' do
      let_it_be(:event1) { create(resource_event, merge_request: merge_request2) }

      it 'returns the expected issuable' do
        expect(event1.issuable).to eq(merge_request2)
      end
    end
  end

  context 'on callbacks' do
    it 'does not trigger note created subscription' do
      event = build(resource_event, merge_request: merge_request1)

      expect(GraphqlTriggers).not_to receive(:work_item_note_created)
      expect(event).not_to receive(:trigger_note_subscription_create)
      event.save!
    end
  end
end

RSpec.shared_examples 'a note for work item resource event' do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:work_item) { create(:work_item, :task, project: project, author: user) }

  let(:resource_event) { described_class.name.demodulize.underscore.to_sym }

  it 'builds synthetic note with correct synthetic_note_class' do
    event = build(resource_event, issue: work_item)

    expect(event.work_item_synthetic_system_note.class.name).to eq(event.synthetic_note_class.name)
  end

  context 'on callbacks' do
    it 'triggers note created subscription' do
      event = build(resource_event, issue: work_item)

      expect(GraphqlTriggers).to receive(:work_item_note_created)
      expect(event).to receive(:trigger_note_subscription_create).and_call_original
      event.save!
    end
  end
end
