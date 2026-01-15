# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../../../lib/authn/token_field/generator/routable_token'
require_relative '../../../../../../lib/authn/token_field/decoders/v1/routable_payload'

RSpec.describe Authn::TokenField::Decoders::V1::RoutablePayload, feature_category: :system_access do
  subject(:payload) { described_class.new(token).decode }

  let(:token) { "glrtr-W5m1cHR6skC98Bx7XkuYjmM6MQpnOjgKbzpyegp0OjIQ.01.181uebm4k" }

  describe '#decode' do
    it 'decodes the payload' do
      expect(payload).to eq({ "c" => 1, "g" => 8, "o" => 1007, "t" => 2 })
    end

    context 'with invalid token' do
      context 'when crc is not correct' do
        let(:token) { "glrtr-W5m1cHR6skC98Bx7XkuYjmM6MQpnOjgKbzpyegp0OjIQ.01.181uebm4l" }

        it { is_expected.to be_nil }
      end

      context 'when token does not have dots' do
        let(:encodable_payload) { "glrtr-W5m1cHR6skC98Bx7XkuYjmM6MQpnOjgKbzpyegp0OjIQ" }
        let(:token) { "#{encodable_payload}#{::Authn::TokenField::Generator::RoutableToken.crc_of(encodable_payload)}" }

        it { is_expected.to be_nil }
      end

      context 'when token prefix is incorrect' do
        let(:encodable_payload) { "wrong-glrtr-W5m1cHR6skC98Bx7XkuYjmM6MQpnOjgKbzpyegp0OjIQ.01.181uebm4k" }
        let(:token) { "#{encodable_payload}#{::Authn::TokenField::Generator::RoutableToken.crc_of(encodable_payload)}" }

        it { is_expected.to be_nil }
      end

      context 'when token payload is empty hash' do
        let(:encodable_payload) { "glrtr-8CLoDbhWwqW3qiRbgpHYEwA.01.0n" }
        let(:token) { "#{encodable_payload}#{::Authn::TokenField::Generator::RoutableToken.crc_of(encodable_payload)}" }

        it { is_expected.to be_nil }
      end

      context 'when token payload is just an array, not a hash' do
        let(:encodable_payload) { "glrtr-igz7z_MRijGFhUQwq0FCzWEKeAoxCjIH.01.0w" }
        let(:token) { "#{encodable_payload}#{::Authn::TokenField::Generator::RoutableToken.crc_of(encodable_payload)}" }

        it { is_expected.to be_nil }
      end
    end
  end
end
