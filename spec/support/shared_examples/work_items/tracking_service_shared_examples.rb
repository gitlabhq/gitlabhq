# frozen_string_literal: true

RSpec.shared_examples 'tracks work item event' do |work_item_var, user_var, event_name, method_to_call = nil|
  it "calls the instrumentation service with '#{event_name}' event" do
    tracking_service = instance_double(Gitlab::WorkItems::Instrumentation::TrackingService)

    # Resolve the variables using send
    work_item = send(work_item_var)
    user = send(user_var)

    allow(Gitlab::WorkItems::Instrumentation::TrackingService)
      .to receive(:new)
      .and_return(tracking_service)

    allow(tracking_service).to receive(:execute)

    if method_to_call
      send(method_to_call)
    else
      service.execute
    end

    expect(Gitlab::WorkItems::Instrumentation::TrackingService)
      .to have_received(:new)
      .with(
        work_item: work_item,
        current_user: user,
        event: event_name
      )

    expect(tracking_service).to have_received(:execute).at_least(:once)
  end
end

RSpec.shared_examples 'does not track work item event' do |method_to_call = nil|
  it 'does not call the InstrumentationService' do
    expect(Gitlab::WorkItems::Instrumentation::TrackingService).not_to receive(:new)

    if method_to_call
      send(method_to_call)
    else
      service.execute
    end
  end
end

RSpec.shared_examples 'tracks non work item event' do |user_var, event_name, method_to_call = nil|
  it "calls TrackingService.track with '#{event_name}' event" do
    allow(Gitlab::WorkItems::Instrumentation::TrackingService).to receive(:track)

    if method_to_call
      send(method_to_call)
    else
      service.execute
    end

    expect(Gitlab::WorkItems::Instrumentation::TrackingService)
      .to have_received(:track)
      .with(
        event: event_name,
        properties: hash_including(user: send(user_var))
      )
  end
end

RSpec.shared_examples 'does not track non work item event' do |method_to_call = nil|
  it 'does not call TrackingService.track' do
    expect(Gitlab::WorkItems::Instrumentation::TrackingService).not_to receive(:track)

    if method_to_call
      send(method_to_call)
    else
      service.execute
    end
  end
end
