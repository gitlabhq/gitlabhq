# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::AlertManagement::Fingerprint do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:alert) { create(:alert_management_alert) }

  describe '.generate' do
    subject { described_class.generate(data) }

    context 'when data is an array' do
      let(:data) { [1, 'fingerprint', 'given'] }

      it 'flattens the array' do
        expect_next_instance_of(described_class) do |obj|
          expect(obj).to receive(:flatten_array)
        end

        subject
      end

      it 'returns the hashed fingerprint' do
        expected_fingerprint = Digest::SHA1.hexdigest(data.flatten.map!(&:to_s).join)
        expect(subject).to eq(expected_fingerprint)
      end
    end

    context 'when data is a non-array type' do
      where(:data) do
        [
          111,
          'fingerprint',
          :fingerprint,
          true,
          { test: true }
        ]
      end

      with_them do
        it 'performs like a hashed fingerprint' do
          expect(subject).to eq(Digest::SHA1.hexdigest(data.to_s))
        end
      end
    end
  end
end
