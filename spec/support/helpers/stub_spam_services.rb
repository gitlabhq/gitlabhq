# frozen_string_literal: true

module StubSpamServices
  def stub_spam_services
    allow(::Spam::SpamParams).to receive(:new_from_request) do
      ::Spam::SpamParams.new(
        captcha_response: double(:captcha_response),
        spam_log_id: double(:spam_log_id),
        ip_address: double(:ip_address),
        user_agent: double(:user_agent),
        referer: double(:referer)
      )
    end

    allow_next_instance_of(::Spam::SpamActionService) do |service|
      allow(service).to receive(:execute)
    end

    allow_next_instance_of(::UserAgentDetailService) do |service|
      allow(service).to receive(:create)
    end
  end
end
