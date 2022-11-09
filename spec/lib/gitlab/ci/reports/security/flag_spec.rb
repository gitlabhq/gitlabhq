# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Reports::Security::Flag do
  subject(:security_flag) { described_class.new(type: 'flagged-as-likely-false-positive', origin: 'post analyzer X', description: 'static string to sink') }

  describe '#initialize' do
    context 'when all params are given' do
      it 'initializes an instance' do
        expect { subject }.not_to raise_error

        expect(subject).to have_attributes(
          type: 'flagged-as-likely-false-positive',
          origin: 'post analyzer X',
          description: 'static string to sink'
        )
      end
    end

    describe '#to_h' do
      it 'returns expected hash' do
        expect(security_flag.to_h).to eq(
          {
            flag_type: :false_positive,
            origin: 'post analyzer X',
            description: 'static string to sink'
          }
        )
      end
    end

    describe '#false_positive?' do
      subject { security_flag.false_positive? }

      it { is_expected.to be_truthy }
    end
  end
end
