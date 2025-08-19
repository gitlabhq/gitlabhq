# frozen_string_literal: true

RSpec.shared_examples 'creates the milestone' do |with_hooks:, with_event:|
  it 'conditionally executes hooks with create action and creates new event' do
    if with_hooks
      expect(container).to receive(:execute_hooks).with(a_hash_including(action: 'create'),
        :milestone_hooks)
    end

    expect(Event).to receive(:new).exactly(1).time.and_call_original if with_event

    expect { service.execute }.to change { Milestone.count }.by(1)
  end
end

RSpec.shared_examples 'reopens the milestone' do |with_hooks:, with_event:|
  it 'conditionally executes hooks with reopen action and creates new event' do
    if with_hooks
      expect(milestone.parent).to receive(:execute_hooks).with(a_hash_including(action: 'reopen'),
        :milestone_hooks)
    end

    expect(Event).to receive(:new).exactly(1).time.and_call_original if with_event

    expect { service.execute(milestone) }.to change { milestone.state }.to('active')
  end
end

RSpec.shared_examples 'closes the milestone' do |with_hooks:, with_event:|
  it 'conditionally executes hooks with close action and creates new event' do
    if with_hooks
      expect(milestone.parent).to receive(:execute_hooks).with(a_hash_including(action: 'close'),
        :milestone_hooks)
    end

    expect(Event).to receive(:new).exactly(1).time.and_call_original if with_event

    expect { service.execute(milestone) }.to change { milestone.state }.to('closed')
  end
end
