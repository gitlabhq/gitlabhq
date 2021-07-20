# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::Security::Scan do
  describe '#initialize' do
    subject { described_class.new(params.with_indifferent_access) }

    let(:params) do
      {
        status: 'success',
        type: 'dependency-scanning',
        start_time: 'placeholer',
        end_time: 'placholder'
      }
    end

    context 'when all params are given' do
      it 'initializes an instance' do
        expect { subject }.not_to raise_error

        expect(subject).to have_attributes(
          status: 'success',
          type: 'dependency-scanning',
          start_time: 'placeholer',
          end_time: 'placholder'
        )
      end
    end

    describe '#to_hash' do
      subject { described_class.new(params.with_indifferent_access).to_hash }

      it 'returns expected hash' do
        is_expected.to eq(
          {
            status: 'success',
            type: 'dependency-scanning',
            start_time: 'placeholer',
            end_time: 'placholder'
          }
        )
      end
    end
  end
end
