# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::Security::FindingSignature, feature_category: :vulnerability_management do
  subject { described_class.new(params.with_indifferent_access) }

  let(:params) do
    {
      algorithm_type: 'hash',
      signature_value: 'SIGNATURE'
    }
  end

  describe '#initialize' do
    context 'when a supported algorithm type is given' do
      it 'allows itself to be created' do
        expect(subject.algorithm_type).to eq(params[:algorithm_type])
        expect(subject.signature_value).to eq(params[:signature_value])
      end

      describe '#valid?' do
        it 'returns true' do
          expect(subject.valid?).to eq(true)
        end
      end
    end
  end

  describe '#signature_hex' do
    let(:signature) { described_class.new(**params, qualified_signature: qualified_signature) }

    subject { signature.signature_hex }

    context 'when it is a qualified signature' do
      let(:qualified_signature) { true }

      it { is_expected.to eq('694b90bd9523ef4ec1dfb3adc9ce942d809b32fc') }
    end

    context 'when it is not a qualified signature' do
      let(:qualified_signature) { false }

      it { is_expected.to eq('793b17717327dc39b653cec1b3320595d9050a06') }
    end
  end

  describe '#valid?' do
    context 'when supported algorithm_type is given' do
      it 'is valid' do
        expect(subject.valid?).to eq(true)
      end
    end

    context 'when an unsupported algorithm_type is given' do
      let(:params) do
        {
          algorithm_type: 'INVALID',
          signature_value: 'SIGNATURE'
        }
      end

      it 'is not valid' do
        expect(subject.valid?).to eq(false)
      end
    end
  end

  describe '#to_hash' do
    it 'returns a hash representation of the signature' do
      expect(subject.to_hash).to eq(
        algorithm_type: params[:algorithm_type],
        signature_sha: Digest::SHA1.digest(params[:signature_value])
      )
    end
  end
end
