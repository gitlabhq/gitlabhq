# frozen_string_literal: true

RSpec.shared_examples 'returning an error service response' do |message: nil, reason: nil|
  it 'returns an error service response' do
    result = subject

    expect(result).to be_error

    expect(result.message).to eq(message) if message
    expect(result.reason).to eq(reason) if reason
  end
end

RSpec.shared_examples 'returning a success service response' do |message: nil|
  it 'returns a success service response' do
    result = subject

    expect(result).to be_success

    expect(result.message).to eq(message) if message
  end
end
