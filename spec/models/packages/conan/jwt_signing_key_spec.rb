# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Conan::JwtSigningKey, feature_category: :package_registry do
  include ExclusiveLeaseHelpers

  describe 'validations' do
    it { is_expected.to validate_presence_of(:secret_key) }
  end

  describe 'encryption' do
    it 'stores the secret_key encrypted at rest' do
      secret = SecureRandom.hex(4)
      record = create(:conan_jwt_signing_key, secret_key: secret)

      expect(record.secret_key).to eq(secret)
      expect(record.ciphertext_for(:secret_key)).not_to include(secret)
    end
  end

  describe 'serialization' do
    it 'excludes secret_key from serializable_hash' do
      record = create(:conan_jwt_signing_key, secret_key: SecureRandom.hex(4))

      expect(record.serializable_hash).not_to have_key('secret_key')
    end
  end

  describe '.current_secret_key' do
    subject(:current_secret_key) { described_class.current_secret_key }

    context 'when no record exists' do
      it 'seeds a single record with a freshly generated secret' do
        expect { current_secret_key }.to change { described_class.count }.from(0).to(1)

        expect(described_class.last.secret_key).to match(/\A[0-9a-f]{128}\z/)
      end

      it 'returns the newly seeded secret' do
        expect(current_secret_key).to eq(described_class.last.secret_key)
      end
    end

    context 'when a record already exists' do
      let_it_be(:existing_secret) { SecureRandom.hex(4) }
      let_it_be(:existing) { create(:conan_jwt_signing_key, secret_key: existing_secret) }

      it 'does not create a new record' do
        expect { current_secret_key }.not_to change { described_class.count }
      end

      it 'returns the stored key' do
        expect(current_secret_key).to eq(existing_secret)
      end
    end

    it 'returns the same key on subsequent reads' do
      first_key = described_class.current_secret_key

      expect(described_class.current_secret_key).to eq(first_key)
    end

    context 'when multiple records exist' do
      let_it_be(:older_secret) { SecureRandom.hex(4) }
      let_it_be(:newer_secret) { SecureRandom.hex(4) }
      let_it_be(:older) { create(:conan_jwt_signing_key, secret_key: older_secret) }
      let_it_be(:newer) { create(:conan_jwt_signing_key, secret_key: newer_secret) }

      it 'returns the most recently created key' do
        expect(current_secret_key).to eq(newer_secret)
      end
    end
  end

  describe '.all_secret_keys' do
    subject(:all_secret_keys) { described_class.all_secret_keys }

    context 'when no record exists' do
      it 'seeds a record and returns its key' do
        expect { all_secret_keys }.to change { described_class.count }.from(0).to(1)

        expect(all_secret_keys).to eq([described_class.last.secret_key])
      end
    end

    context 'when multiple records exist' do
      let_it_be(:first_secret) { SecureRandom.hex(4) }
      let_it_be(:second_secret) { SecureRandom.hex(4) }
      let_it_be(:first_key, refind: true) { create(:conan_jwt_signing_key, secret_key: first_secret) }
      let_it_be(:second_key) { create(:conan_jwt_signing_key, secret_key: second_secret) }

      it 'returns every stored key ordered by id' do
        expect(all_secret_keys).to eq([first_secret, second_secret])
      end

      context 'when a record has a blank key' do
        it 'is rejected by the not-null constraint' do
          expect { first_key.update_column(:secret_key, nil) }.to raise_error(ActiveRecord::NotNullViolation)
        end
      end

      context 'when a record cannot be decrypted' do
        before do
          allow(first_key).to receive(:secret_key).and_raise(ActiveRecord::Encryption::Errors::Decryption)
          allow(described_class).to receive(:ordered).and_return([first_key, second_key])
          allow(Gitlab::ErrorTracking).to receive(:track_exception)
        end

        it 'skips the record and tracks the exception instead of raising' do
          expect(all_secret_keys).to eq([second_secret])
          expect(Gitlab::ErrorTracking).to have_received(:track_exception)
            .with(instance_of(ActiveRecord::Encryption::Errors::Decryption))
        end
      end
    end
  end

  describe 'seeding concurrency' do
    it 'creates only one record when multiple callers race to seed an empty table' do
      threads = Array.new(3) { Thread.new { described_class.current_secret_key } }
      threads.each(&:join)

      expect(described_class.count).to eq(1)
    end

    context 'when the seeding lease cannot be obtained' do
      before do
        stub_exclusive_lease_taken('Packages::Conan::JwtSigningKey#seed!', timeout: 15.seconds)
      end

      it 'raises instead of silently returning without a key' do
        expect { described_class.current_secret_key }
          .to raise_error(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
      end
    end
  end
end
