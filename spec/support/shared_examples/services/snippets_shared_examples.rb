# frozen_string_literal: true

RSpec.shared_examples 'checking spam' do
  let(:request) { double(:request, headers: headers) }
  let(:headers) { nil }
  let(:api) { true }
  let(:captcha_response) { 'abc123' }
  let(:spam_log_id) { 1 }
  let(:disable_spam_action_service) { false }

  let(:extra_opts) do
    {
      request: request,
      api: api,
      captcha_response: captcha_response,
      spam_log_id: spam_log_id,
      disable_spam_action_service: disable_spam_action_service
    }
  end

  before do
    allow_next_instance_of(UserAgentDetailService) do |instance|
      allow(instance).to receive(:create)
    end
  end

  it 'executes SpamActionService' do
    spam_params = Spam::SpamParams.new(
      api: api,
      captcha_response: captcha_response,
      spam_log_id: spam_log_id
    )
    expect_next_instance_of(
      Spam::SpamActionService,
      {
        spammable: kind_of(Snippet),
        request: request,
        user: an_instance_of(User),
        action: action
      }
    ) do |instance|
      expect(instance).to receive(:execute).with(spam_params: spam_params)
    end

    subject
  end

  context 'when CAPTCHA arguments are passed in the headers' do
    let(:headers) do
      {
        'X-GitLab-Spam-Log-Id' => spam_log_id,
        'X-GitLab-Captcha-Response' => captcha_response
      }
    end

    let(:extra_opts) do
      {
        request: request,
        api: api,
        disable_spam_action_service: disable_spam_action_service
      }
    end

    it 'executes the SpamActionService correctly' do
      spam_params = Spam::SpamParams.new(
        api: api,
        captcha_response: captcha_response,
        spam_log_id: spam_log_id
      )
      expect_next_instance_of(
        Spam::SpamActionService,
        {
          spammable: kind_of(Snippet),
          request: request,
          user: an_instance_of(User),
          action: action
        }
      ) do |instance|
        expect(instance).to receive(:execute).with(spam_params: spam_params)
      end

      subject
    end
  end

  context 'when spam action service is disabled' do
    let(:disable_spam_action_service) { true }

    it 'request parameter is not passed to the service' do
      expect(Spam::SpamActionService).not_to receive(:new)

      subject
    end
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
