# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::AlertManagement::Fingerprint do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:alert) { create(:alert_management_alert) }

  describe '.generate' do
    subject { described_class.generate(data) }

    context 'when data is an array' do
      let(:data) { [1, 'fingerprint', 'given'] }

      it 'returns the hashed fingerprint' do
        expected_fingerprint = Digest::SHA1.hexdigest(data.flatten.map!(&:to_s).join)
        expect(subject).to eq(expected_fingerprint)
      end

      context 'with a variety of data' do
        where(:data) do
          [
            111,
            'fingerprint',
            :fingerprint,
            true
          ]
        end

        with_them do
          it 'performs like a hashed fingerprint' do
            expect(subject).to eq(Digest::SHA1.hexdigest(data.to_s))
          end
        end
      end
    end

    context 'when data is a hash' do
      let(:data) { { test: true } }

      shared_examples 'fingerprinted Hash' do
        it 'performs like a hashed fingerprint' do
          flattened_hash = Gitlab::Utils::SafeInlineHash.merge_keys!(data).sort.to_s
          expect(subject).to eq(Digest::SHA1.hexdigest(flattened_hash))
        end
      end

      it_behaves_like 'fingerprinted Hash'

      context 'hashes with different order' do
        it 'calculates the same result' do
          data = { test: true, another_test: 1 }
          data_hash = described_class.generate(data)

          reverse_data = { another_test: 1, test: true }
          reverse_data_hash = described_class.generate(reverse_data)

          expect(data_hash).to eq(reverse_data_hash)
        end
      end

      context 'hash is too large' do
        before do
          expect_next_instance_of(Gitlab::Utils::SafeInlineHash) do |obj|
            expect(obj).to receive(:valid?).and_return(false)
          end
        end

        it 'raises an error' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
