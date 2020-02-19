# frozen_string_literal: true

require 'spec_helper'

describe ResourceEvents::ChangeMilestoneService do
  shared_examples 'milestone events creator' do
    let_it_be(:user) { create(:user) }

    let_it_be(:milestone) { create(:milestone) }

    context 'when milestone is present' do
      before do
        resource.milestone = milestone
      end

      let(:service) { described_class.new(resource: resource, user: user, created_at: created_at_time) }

      it 'creates the expected event record' do
        expect { service.execute }.to change { ResourceMilestoneEvent.count }.from(0).to(1)

        events = ResourceMilestoneEvent.all

        expect(events.size).to eq(1)
        expect_event_record(events.first, action: 'add', milestone: milestone, state: 'opened')
      end
    end

    context 'when milestones is not present' do
      before do
        resource.milestone = nil
      end

      let(:service) { described_class.new(resource: resource, user: user, created_at: created_at_time) }

      it 'creates the expected event records' do
        expect { service.execute }.to change { ResourceMilestoneEvent.count }.from(0).to(1)

        expect_event_record(ResourceMilestoneEvent.first, action: 'remove', milestone: nil, state: 'opened')
      end
    end

    def expect_event_record(event, expected_attrs)
      expect(event.action).to eq(expected_attrs[:action])
      expect(event.state).to eq(expected_attrs[:state])
      expect(event.user).to eq(user)
      expect(event.issue).to eq(resource) if resource.is_a?(Issue)
      expect(event.issue).to be_nil unless resource.is_a?(Issue)
      expect(event.merge_request).to eq(resource) if resource.is_a?(MergeRequest)
      expect(event.merge_request).to be_nil unless resource.is_a?(MergeRequest)
      expect(event.milestone).to eq(expected_attrs[:milestone])
      expect(event.created_at).to eq(created_at_time)
    end
  end

  let_it_be(:merge_request) { create(:merge_request) }
  let_it_be(:issue) { create(:issue) }

  let!(:created_at_time) { Time.utc(2019, 12, 30) }

  it_behaves_like 'milestone events creator' do
    let(:resource) { issue }
  end

  it_behaves_like 'milestone events creator' do
    let(:resource) { merge_request }
  end
end
