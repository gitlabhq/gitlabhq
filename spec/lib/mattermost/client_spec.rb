# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mattermost::Client, feature_category: :integrations do
  let(:user) { build(:user) }

  subject { described_class.new(user) }

  context 'JSON parse error' do
    before do
      Struct.new("Request", :body, :success?)
    end

    it 'yields an error on malformed JSON' do
      response = instance_double(HTTParty::Response)
      allow(response).to receive(:parsed_response).and_raise(JSON::JSONError)

      expect { subject.send(:json_response, response) }
        .to raise_error(::Mattermost::ClientError, 'Cannot parse response')
    end

    it 'shows a client error if the request was unsuccessful' do
      response = instance_double(HTTParty::Response, parsed_response: { 'message' => 'Error' }, success?: false)

      expect { subject.send(:json_response, response) }.to raise_error(::Mattermost::ClientError, 'Error')
    end
  end
end
