# frozen_string_literal: true

# This shared_example requires the following variables:
# - current_user
# - group
# - type, the issuable type (ie :issues, :merge_requests)
# - count_service, the Service used by the specified issuable type

RSpec.shared_examples 'cached issuables count' do
  subject { helper.cached_issuables_count(group, type: type) }

  before do
    allow(helper).to receive(:current_user) { current_user }
    allow(count_service).to receive(:new).and_call_original
  end

  it 'calls the correct service class' do
    subject
    expect(count_service).to have_received(:new).with(group, current_user)
  end

  it 'returns all digits for count value under 1000' do
    allow_next_instance_of(count_service) do |service|
      allow(service).to receive(:count).and_return(999)
    end

    expect(subject).to eq('999')
  end

  it 'returns truncated digits for count value over 1000' do
    allow_next_instance_of(count_service) do |service|
      allow(service).to receive(:count).and_return(2300)
    end

    expect(subject).to eq('2.3k')
  end

  it 'returns truncated digits for count value over 10000' do
    allow_next_instance_of(count_service) do |service|
      allow(service).to receive(:count).and_return(12560)
    end

    expect(subject).to eq('12.6k')
  end

  it 'returns truncated digits for count value over 100000' do
    allow_next_instance_of(count_service) do |service|
      allow(service).to receive(:count).and_return(112560)
    end

    expect(subject).to eq('112.6k')
  end
end
