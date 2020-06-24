# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Saml::OriginValidator do
  let(:session) { instance_double(ActionDispatch::Request::Session) }

  subject { described_class.new(session) }

  describe '#store_origin' do
    it 'stores the SAML request ID' do
      request_id = double
      authn_request = instance_double(OneLogin::RubySaml::Authrequest, uuid: request_id)

      expect(session).to receive(:[]=).with('last_authn_request_id', request_id)

      subject.store_origin(authn_request)
    end
  end

  describe '#gitlab_initiated?' do
    it 'returns false if InResponseTo is not present' do
      saml_response = instance_double(OneLogin::RubySaml::Response, in_response_to: nil)

      expect(subject.gitlab_initiated?(saml_response)).to eq(false)
    end

    it 'returns false if InResponseTo does not match stored value' do
      saml_response = instance_double(OneLogin::RubySaml::Response, in_response_to: "abc")
      allow(session).to receive(:[]).with('last_authn_request_id').and_return('123')

      expect(subject.gitlab_initiated?(saml_response)).to eq(false)
    end

    it 'returns true if InResponseTo matches stored value' do
      saml_response = instance_double(OneLogin::RubySaml::Response, in_response_to: "123")
      allow(session).to receive(:[]).with('last_authn_request_id').and_return('123')

      expect(subject.gitlab_initiated?(saml_response)).to eq(true)
    end
  end
end
