# frozen_string_literal: true

RSpec.shared_examples 'timebox(milestone or iteration) resource events creator' do |timebox_event_class|
  let_it_be(:user) { create(:user) }

  before do
    resource.system_note_timestamp = created_at_time
  end

  context 'when milestone/iteration is added' do
    let(:service) { described_class.new(resource, user, **add_timebox_args) }

    before do
      set_timebox(timebox_event_class, timebox)
    end

    it 'creates the expected event record' do
      expect { service.execute }.to change { timebox_event_class.count }.by(1)

      expect_event_record(timebox_event_class, timebox_event_class.last, action: 'add', state: 'opened', timebox: timebox)
    end
  end

  context 'when milestone/iteration is removed' do
    let(:service) { described_class.new(resource, user, **remove_timebox_args) }

    before do
      set_timebox(timebox_event_class, nil)
    end

    it 'creates the expected event records' do
      expect { service.execute }.to change { timebox_event_class.count }.by(1)

      expect_event_record(timebox_event_class, timebox_event_class.last, action: 'remove', timebox: timebox, state: 'opened')
    end
  end

  def expect_event_record(timebox_event_class, event, expected_attrs)
    expect(event.action).to eq(expected_attrs[:action])
    expect(event.user).to eq(user)
    expect(event.issue).to eq(resource) if resource.is_a?(Issue)
    expect(event.issue).to be_nil unless resource.is_a?(Issue)
    expect(event.merge_request).to eq(resource) if resource.is_a?(MergeRequest)
    expect(event.merge_request).to be_nil unless resource.is_a?(MergeRequest)
    expect(event.created_at).to eq(created_at_time)
    expect_timebox(timebox_event_class, event, expected_attrs)
  end

  def set_timebox(timebox_event_class, timebox)
    case timebox_event_class.name
    when 'ResourceMilestoneEvent'
      resource.milestone = timebox
    when 'ResourceIterationEvent'
      resource.iteration = timebox
    end
  end

  def expect_timebox(timebox_event_class, event, expected_attrs)
    case timebox_event_class.name
    when 'ResourceMilestoneEvent'
      expect(event.state).to eq(expected_attrs[:state])
      expect(event.milestone).to eq(expected_attrs[:timebox])
    when 'ResourceIterationEvent'
      expect(event.iteration).to eq(expected_attrs[:timebox])
    end
  end
end
