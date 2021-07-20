# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'a mutation which can mutate a spammable' do
  describe "#spam_params" do
    it 'passes spam params to the service constructor' do
      args = [
        project: anything,
        current_user: anything,
        params: anything,
        spam_params: instance_of(::Spam::SpamParams)
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
