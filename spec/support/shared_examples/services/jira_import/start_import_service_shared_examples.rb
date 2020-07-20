# frozen_string_literal: true

RSpec.shared_examples 'responds with error' do |message|
  it 'returns error' do
    expect(subject).to be_a(ServiceResponse)
    expect(subject).to be_error
    expect(subject.message).to eq(message)
  end
end
