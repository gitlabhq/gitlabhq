# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mattermost::Client do
  let(:user) { build(:user) }

  subject { described_class.new(user) }

  context 'JSON parse error' do
    before do
      Struct.new("Request", :body, :success?)
    end

    it 'yields an error on malformed JSON' do
      bad_json = Struct::Request.new("I'm not json", true)
      expect { subject.send(:json_response, bad_json) }.to raise_error(::Mattermost::ClientError)
    end

    it 'shows a client error if the request was unsuccessful' do
      bad_request = Struct::Request.new("true", false)

      expect { subject.send(:json_response, bad_request) }.to raise_error(::Mattermost::ClientError)
    end
  end
end
