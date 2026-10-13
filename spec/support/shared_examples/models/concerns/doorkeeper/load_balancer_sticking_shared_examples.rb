# frozen_string_literal: true

# Expects the including spec to define:
# - `namespace`: the sticking namespace the model uses
# - `record`: a lazily created record whose plaintext secrets are still in memory
# - `lookups`: a Hash of class method name => plaintext secret that finds `record`
# - `expected_stuck_secrets`: the plaintext secrets creating `record` must stick
RSpec.shared_examples 'a Doorkeeper model stuck to the database load balancer' do
  let(:sticking) { described_class.sticking }

  describe 'lookups' do
    it 'routes every lookup of a secret through a caught-up replica', :aggregate_failures do
      lookups.each do |method, plaintext|
        expect(sticking).to receive(:find_caught_up_replica).with(namespace, plaintext, hash_id: true).and_call_original

        expect(described_class.public_send(method, plaintext)).to have_attributes(id: record.id)
      end
    end

    it 'does not stick a blank lookup' do
      expect(sticking).not_to receive(:find_caught_up_replica)

      expect(described_class.public_send(lookups.each_key.first, '')).to be_nil
    end

    it 'does not stick a lookup that is not shaped like a Doorkeeper secret' do
      expect(sticking).not_to receive(:find_caught_up_replica)

      expect(described_class.public_send(lookups.each_key.first, 'glpat-not-an-oauth-token')).to be_nil
    end

    it 'falls back to a normal read when sticking fails', :aggregate_failures do
      method, plaintext = lookups.first
      allow(sticking).to receive(:find_caught_up_replica).and_raise(Redis::CannotConnectError)
      allow(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

      expect(described_class.public_send(method, plaintext)).to have_attributes(id: record.id)
      expect(Gitlab::ErrorTracking).to have_received(:track_and_raise_for_dev_exception)
        .with(an_instance_of(Redis::CannotConnectError), model: described_class.name, namespace: namespace)
    end

    context 'when the oauth_lookups_use_load_balancer_sticking feature flag is disabled' do
      before do
        stub_feature_flags(oauth_lookups_use_load_balancer_sticking: false)
      end

      it 'finds the record without sticking' do
        method, plaintext = lookups.first

        expect(sticking).not_to receive(:find_caught_up_replica)

        expect(described_class.public_send(method, plaintext)).to have_attributes(id: record.id)
      end
    end
  end

  describe 'creation' do
    it 'records the primary write location for every secret the client receives in one call', :aggregate_failures do
      allow(sticking).to receive(:bulk_stick)

      expect(expected_stuck_secrets).to all(be_present)
      expect(sticking)
        .to have_received(:bulk_stick).with(namespace, match_array(expected_stuck_secrets), hash_id: true).once
    end

    it 'still saves the record when sticking fails', :aggregate_failures do
      allow(sticking).to receive(:bulk_stick).and_raise(Redis::CannotConnectError)
      allow(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

      expect(record).to be_persisted
      expect(Gitlab::ErrorTracking).to have_received(:track_and_raise_for_dev_exception)
        .with(an_instance_of(Redis::CannotConnectError), model: record.class.name, record_id: record.id)
    end

    context 'when the stick_new_oauth_tokens_to_primary feature flag is disabled' do
      before do
        stub_feature_flags(stick_new_oauth_tokens_to_primary: false)
      end

      it 'saves the record without sticking' do
        expect(sticking).not_to receive(:bulk_stick)

        expect(record).to be_persisted
      end
    end
  end
end
