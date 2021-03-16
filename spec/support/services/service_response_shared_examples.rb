# frozen_string_literal: true

RSpec.shared_examples 'returning an error service response' do |message: nil|
  it 'returns an error service response' do
    result = subject

    expect(result).to be_error

    if message
      expect(result.message).to eq(message)
    end
  end
end

RSpec.shared_examples 'returning a success service response' do |message: nil|
  it 'returns a success service response' do
    result = subject

    expect(result).to be_success

    if message
      expect(result.message).to eq(message)
    end
  end
end
