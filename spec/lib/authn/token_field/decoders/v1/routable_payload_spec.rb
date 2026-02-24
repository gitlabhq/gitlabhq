# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../../../lib/authn/token_field/generator/routable_token'
require_relative '../../../../../../lib/authn/token_field/decoders/v1/routable_payload'

RSpec.describe Authn::TokenField::Decoders::V1::RoutablePayload, feature_category: :system_access do
  let(:decoder) { described_class.new(token) }
  let(:token) { "glrtr-W5m1cHR6skC98Bx7XkuYjmM6MQpnOjgKbzpyegp0OjIQ.01.181uebm4k" }

  subject(:payload) { decoder.decode }

  describe '#decode' do
    shared_examples 'returning nil without decoding' do
      it 'returns nil without decoding' do
        expect(decoder).not_to receive(:decoded_payload_hash)
        is_expected.to be_nil
      end
    end

    shared_examples 'returning nil with decoding' do
      it 'returns nil without decoding' do
        expect(decoder).to receive(:decoded_payload_hash).and_call_original
        is_expected.to be_nil
      end
    end

    it 'decodes the payload' do
      expect(payload).to eq({ "c" => 1, "g" => 8, "o" => 1007, "t" => 2 })
    end

    context 'with invalid token' do
      context 'when crc is not correct' do
        let(:token) { "glrtr-W5m1cHR6skC98Bx7XkuYjmM6MQpnOjgKbzpyegp0OjIQ.01.181uebm4l" }

        it_behaves_like 'returning nil without decoding'
      end

      context 'when token does not have dots' do
        let(:encodable_payload) { "glrtr-W5m1cHR6skC98Bx7XkuYjmM6MQpnOjgKbzpyegp0OjIQ" }
        let(:token) { "#{encodable_payload}#{::Authn::TokenField::Generator::RoutableToken.crc_of(encodable_payload)}" }

        it_behaves_like 'returning nil without decoding'
      end

      context 'when token prefix is incorrect' do
        let(:encodable_payload) { "wrong-glrtr-W5m1cHR6skC98Bx7XkuYjmM6MQpnOjgKbzpyegp0OjIQ.01.181uebm4k" }
        let(:token) { "#{encodable_payload}#{::Authn::TokenField::Generator::RoutableToken.crc_of(encodable_payload)}" }

        it_behaves_like 'returning nil without decoding'
      end

      context 'when token payload is empty hash' do
        let(:encodable_payload) { "glrtr-8CLoDbhWwqW3qiRbgpHYEwA.01.0n" }
        let(:token) { "#{encodable_payload}#{::Authn::TokenField::Generator::RoutableToken.crc_of(encodable_payload)}" }

        it_behaves_like 'returning nil with decoding'
      end

      context 'when token payload is just an array, not a hash' do
        let(:encodable_payload) { "glrtr-igz7z_MRijGFhUQwq0FCzWEKeAoxCjIH.01.0w" }
        let(:token) { "#{encodable_payload}#{::Authn::TokenField::Generator::RoutableToken.crc_of(encodable_payload)}" }

        it_behaves_like 'returning nil with decoding'
      end

      context 'when token payload is too big over the MAXIMUM_SIZE_OF_ROUTING_PAYLOAD' do
        let(:encodable_payload) do
          # rubocop:disable Layout/LineLength -- a very long invalid token for this spec
          "UzhlpYwQ_BqmCwJJWQzSaWM6MQpvOjgyMWY5Y2FiMjY1YmFjNjdhZGZmZTdiZWIzMmJmZmZkMzAwNmYyMTJiZmM4ZDUyMzU2MzFjNGM2ZDJiZjUxMzg2YmI0ZmUwZDJmY2U3ZDgwZWRiZTRlMGZjMWRlNTZiZmRhMzFiMTRiYTJmODBhNTlkMjJhMGVhZjM1ZTdlMDk3MDgwMGM2YTE0YmY0NDMwYjI2YWYzOTUyMGRmYzVmNDkwMDA5YTE3MjM4ZTNhNjQwYTIyODA5N2Y0YjZlMzU3NGQ2YjRiNjZjMzQ4M2E5ZTY1NDVmNzJjOTAzNTczN2U5NjM0NTZjMmEzZDQxNjZmMWE1NjQ0ODIxOGQxMTlhYmU4NzdiMjUwNTY0OGZkODAwZTk4NWRmZTc4YTMxNDU0MWY4NmQzZWIxNDVjMWJjYzc3NDQ2MzhhYjA1NTg3MGJkOWE0Mjg3MzQyZTQ3ODViMjg1MzM3ZjgwYzY0Yjg3YWY4ZDdjNWIyMGUyMzdjZjNlNzdiMWU1YmJjZDdkNmE0ZTgyYjhhMGU3OGMxY2Q0lA.01.fm"
          # rubocop:enable Layout/LineLength
        end

        let(:token) { "#{encodable_payload}#{::Authn::TokenField::Generator::RoutableToken.crc_of(encodable_payload)}" }

        it_behaves_like 'returning nil without decoding'
      end
    end
  end
end
