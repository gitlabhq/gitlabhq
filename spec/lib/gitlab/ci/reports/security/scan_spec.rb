# frozen_string_literal: true

require 'fast_spec_helper'

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
        expect(subject).to have_attributes(
          status: 'success',
          type: 'dependency-scanning',
          start_time: 'placeholer',
          end_time: 'placholder',
          partial_scan_mode: nil
        )
      end
    end

    context 'when partial scan' do
      let(:params) do
        {
          status: 'success',
          type: 'dependency-scanning',
          start_time: 'placeholer',
          end_time: 'placholder',
          partial_scan: {
            mode: 'differential'
          }
        }
      end

      it 'sets partial_scan_mode attribute' do
        expect(subject).to have_attributes(
          partial_scan_mode: 'differential'
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
