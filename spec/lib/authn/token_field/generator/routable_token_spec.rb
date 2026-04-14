# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../../lib/authn/token_field/generator/routable_token'
require_relative '../../../../support/matchers/token_authenticatable_matchers'

RSpec.describe Authn::TokenField::Generator::RoutableToken, feature_category: :system_access do
  include ::TokenAuthenticatableMatchers

  let(:test_class) { Struct.new(:id) }
  let(:token_owner_record) { test_class.new(id: 1) }
  let(:routing_payload) { {} }
  let(:prefix) { nil }
  let(:generator) do
    described_class.new(token_owner_record, routing_payload: routing_payload, prefix: prefix)
  end

  describe '.random_bytes' do
    it 'generates random bytes' do
      expect(described_class.random_bytes(42).size).to eq(42)
    end
  end

  describe '#initialize' do
    context 'when neither c nor o routing key is present' do
      let(:routing_payload) do
        { p: ->(_) { 'foo' } }
      end

      it 'raises an exception' do
        expect { generator }.to raise_error(described_class::MissingRequiredRoutingKeys,
          "At least one routing key must be present: :c or :o.")
      end
    end

    context 'with only c routing key' do
      let(:routing_payload) do
        { c: ->(_) { 1 } }
      end

      it 'does not raise an exception' do
        expect { generator }.not_to raise_error
      end
    end

    context 'with only o routing key' do
      let(:routing_payload) do
        { o: ->(_) { 1 } }
      end

      it 'does not raise an exception' do
        expect { generator }.not_to raise_error
      end
    end

    context 'with both c and o routing keys' do
      let(:routing_payload) do
        { c: ->(_) { 1 }, o: ->(_) { 1 } }
      end

      it 'does not raise an exception' do
        expect { generator }.not_to raise_error
      end
    end

    context 'with invalid routing keys' do
      let(:routing_payload) do
        { o: 'foo', q: 'bar', k: 'baz' }
      end

      it 'raises an exception' do
        expect { generator }.to raise_error(described_class::InvalidRoutingKeys,
          "Invalid routing keys: :q, :k. Valid routing keys are: :c, :g, :o, :p, :u, :t.")
      end
    end
  end

  describe '#generate_token' do
    let(:random_bytes) { 'a' * described_class::RANDOM_BYTES_LENGTH }
    let(:cell_setting) { { enabled: false, id: nil } }

    subject(:token) { generator.generate_token }

    before do
      allow(described_class)
        .to receive(:random_bytes).with(described_class::RANDOM_BYTES_LENGTH).and_return(random_bytes)
      stub_config({ cell: cell_setting })
    end

    shared_examples 'a routable token' do
      context 'when Settings.cells.id is not present' do
        it 'generates a routable token' do
          expect(token)
            .to be_a_routable_token
            .with_payload("o:#{token_owner_record.id.to_s(36)}")
        end
      end

      context 'when Settings.cells.id is present and cell is enabled' do
        let(:cell_setting) { { enabled: true, id: 100 } }

        it 'generates a routable token' do
          expect(token)
            .to be_a_routable_token
            .with_payload("c:#{cell_setting[:id].to_s(36)}\no:#{token_owner_record.id.to_s(36)}")
        end
      end

      context 'with a prefix set' do
        let(:prefix) { 'prefix-' }

        it 'generates a routable token' do
          expect(token)
            .to be_a_routable_token
            .with_payload("o:#{token_owner_record.id.to_s(36)}")
            .and_prefix(prefix)
        end
      end
    end

    context 'with a routing payload hash' do
      let(:routing_payload) do
        { o: ->(token_owner_record) { token_owner_record.id } }
      end

      it_behaves_like 'a routable token'
    end

    context 'with a too big encodable routing payload' do
      let(:routing_payload) do
        { o: ->(_) { 'a' * 158 } }
      end

      it 'raises an exception' do
        expect { token }.to raise_error(described_class::PayloadTooLarge,
          "Routing payload is too big: 160. " \
            "Maximum size is #{described_class::MAXIMUM_SIZE_OF_ROUTING_PAYLOAD}."
        )
      end
    end

    context 'with a routing payload with string value' do
      let(:routing_payload) do
        { o: ->(_) { 'foo' } }
      end

      it 'generates a routable token' do
        expect(token)
          .to be_a_routable_token
          .with_payload("o:foo")
      end
    end

    context 'with only c routing key (cell-scoped token)' do
      let(:cell_setting) { { enabled: true, id: 100 } }

      let(:routing_payload) do
        { c: ->(_) { 1 } }
      end

      it 'generates a routable token with c payload only' do
        expect(token)
          .to be_a_routable_token
          .with_payload("c:1")
      end

      it 'uses the explicitly provided c value instead of the default cell id' do
        expect(decoded_routing_payload(token)).to eq("c:1")
        expect(decoded_routing_payload(token)).not_to include("c:#{cell_setting[:id].to_s(36)}")
      end
    end

    context 'with c and p routing keys (no o)' do
      let(:cell_setting) { { enabled: true, id: 100 } }

      let(:routing_payload) do
        { c: ->(_) { 1 }, p: ->(_) { 'proj' } }
      end

      it 'generates a routable token with c and p payload' do
        expect(token)
          .to be_a_routable_token
          .with_payload("c:1\np:proj")
      end

      it 'uses the explicitly provided c value instead of the default cell id' do
        expect(decoded_routing_payload(token)).to start_with("c:1")
        expect(decoded_routing_payload(token)).not_to include("c:#{cell_setting[:id].to_s(36)}")
      end
    end

    context 'when no c key is provided and cell is configured' do
      let(:cell_setting) { { enabled: true, id: 100 } }

      let(:routing_payload) do
        { o: ->(record) { record.id } }
      end

      it 'falls back to the default cell id from settings' do
        expect(token)
          .to be_a_routable_token
          .with_payload("c:#{cell_setting[:id].to_s(36)}\no:#{token_owner_record.id.to_s(36)}")
      end
    end

    context 'when no c key is provided and cell id is nil' do
      let(:cell_setting) { { enabled: false, id: nil } }

      let(:routing_payload) do
        { o: ->(record) { record.id } }
      end

      it 'omits the c key from the payload' do
        expect(decoded_routing_payload(token)).to eq("o:#{token_owner_record.id.to_s(36)}")
        expect(decoded_routing_payload(token)).not_to include("c:")
      end
    end

    context 'with o and p routing keys' do
      let(:routing_payload) do
        { o: ->(record) { record.id }, p: ->(_) { 'proj' } }
      end

      it 'generates a routable token with o and p payload' do
        expect(token)
          .to be_a_routable_token
          .with_payload("o:#{token_owner_record.id.to_s(36)}\np:proj")
      end
    end

    context 'with c, o, and p routing keys' do
      let(:cell_setting) { { enabled: true, id: 100 } }

      let(:routing_payload) do
        { o: ->(record) { record.id }, p: ->(_) { 'proj' } }
      end

      it 'generates a routable token with c, o, and p payload' do
        expect(token)
          .to be_a_routable_token
          .with_payload("c:#{cell_setting[:id].to_s(36)}\no:#{token_owner_record.id.to_s(36)}\np:proj")
      end
    end

    context 'with o, p, and u routing keys' do
      let(:routing_payload) do
        { o: ->(record) { record.id }, p: ->(_) { 'proj' }, u: ->(_) { 'usr' } }
      end

      it 'generates a routable token with o, p, and u payload' do
        expect(token)
          .to be_a_routable_token
          .with_payload("o:#{token_owner_record.id.to_s(36)}\np:proj\nu:usr")
      end
    end

    context 'with actual random bytes generated' do
      let(:routing_payload) do
        { o: ->(token_owner_record) { token_owner_record.id } }
      end

      before do
        allow(described_class).to receive(:random_bytes).with(described_class::RANDOM_BYTES_LENGTH).and_call_original
      end

      it 'uses a different random_bytes value on each call' do
        first_token = token

        expect(first_token)
          .to be_a_routable_token
          .with_prefix(prefix)

        second_token = generator.generate_token

        expect(second_token)
          .to be_a_routable_token
          .with_prefix(prefix)
        expect(first_token)
          .to have_different_random_bytes_than(second_token)
          .with_prefix(prefix)
        expect(second_token).not_to eq(first_token)
      end
    end
  end
end
