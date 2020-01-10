# frozen_string_literal: true

# This shared_example requires the following variables:
#   let(:service_class) { Gitlab::DatabaseImporters::SelfMonitoring::Project::DeleteService }
#   let(:service) { instance_double(service_class) }
RSpec.shared_examples 'executes service' do
  before do
    allow(service_class).to receive(:new) { service }
  end

  it 'runs the service' do
    expect(service).to receive(:execute)

    subject.perform
  end
end

RSpec.shared_examples 'returns in_progress based on Sidekiq::Status' do
  it 'returns true when job is enqueued' do
    jid = described_class.perform_async

    expect(described_class.in_progress?(jid)).to eq(true)
  end

  it 'returns false when job does not exist' do
    expect(described_class.in_progress?('fake_jid')).to eq(false)
  end
end
