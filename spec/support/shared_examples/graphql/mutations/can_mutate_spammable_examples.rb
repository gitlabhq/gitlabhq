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
end
