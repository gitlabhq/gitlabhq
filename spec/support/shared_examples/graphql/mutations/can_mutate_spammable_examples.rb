# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'a mutation which can mutate a spammable' do
  describe "#additional_spam_params" do
    it 'passes additional spam params to the service' do
      args = [
        anything,
        anything,
        hash_including(
          api: true,
          request: instance_of(ActionDispatch::Request),
          captcha_response: captcha_response,
          spam_log_id: spam_log_id
        )
      ]
      expect(service).to receive(:new).with(*args).and_call_original

      subject
    end
  end

  describe "#spam_action_response_fields" do
    it 'resolves with spam action fields' do
      subject

      # NOTE: We do not need to assert on the specific values of spam action fields here, we only need
      # to verify that #spam_action_response_fields was invoked and that the fields are present in the
      # response. The specific behavior of #spam_action_response_fields is covered in the
      # HasSpamActionResponseFields unit tests.
      expect(mutation_response.keys)
        .to include('spam', 'spamLogId', 'needsCaptchaResponse', 'captchaSiteKey')
    end
  end
end
