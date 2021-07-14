# frozen_string_literal: true

RSpec.shared_examples 'checking spam' do
  before do
    allow_next_instance_of(UserAgentDetailService) do |instance|
      allow(instance).to receive(:create)
    end
  end

  it 'executes SpamActionService' do
    expect_next_instance_of(
      Spam::SpamActionService,
      {
        spammable: kind_of(Snippet),
        spam_params: spam_params,
        user: an_instance_of(User),
        action: action
      }
    ) do |instance|
      expect(instance).to receive(:execute)
    end

    subject
  end
end

shared_examples 'invalid params error response' do
  before do
    allow_next_instance_of(described_class) do |service|
      allow(service).to receive(:valid_params?).and_return false
    end
  end

  it 'responds to errors appropriately' do
    response = subject

    aggregate_failures do
      expect(response).to be_error
      expect(response.http_status).to eq 422
    end
  end
end
