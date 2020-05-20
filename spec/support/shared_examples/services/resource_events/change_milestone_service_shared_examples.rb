# frozen_string_literal: true

shared_examples 'a milestone events creator' do
  let_it_be(:user) { create(:user) }

  let(:created_at_time) { Time.utc(2019, 12, 30) }
  let(:service) { described_class.new(resource, user, created_at: created_at_time, old_milestone: nil) }

  context 'when milestone is present' do
    let_it_be(:milestone) { create(:milestone) }

    before do
      resource.milestone = milestone
    end

    it 'creates the expected event record' do
      expect { service.execute }.to change { ResourceMilestoneEvent.count }.by(1)

      expect_event_record(ResourceMilestoneEvent.last, action: 'add', milestone: milestone, state: 'opened')
    end
  end

  context 'when milestones is not present' do
    before do
      resource.milestone = nil
    end

    let(:old_milestone) { create(:milestone, project: resource.project) }
    let(:service) { described_class.new(resource, user, created_at: created_at_time, old_milestone: old_milestone) }

    it 'creates the expected event records' do
      expect { service.execute }.to change { ResourceMilestoneEvent.count }.by(1)

      expect_event_record(ResourceMilestoneEvent.last, action: 'remove', milestone: old_milestone, state: 'opened')
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
