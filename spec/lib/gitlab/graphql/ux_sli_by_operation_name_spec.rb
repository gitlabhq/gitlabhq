# frozen_string_literal: true

require 'fast_spec_helper'
require 'labkit/metrics'
require 'labkit/user_experience_sli'

RSpec.describe Gitlab::Graphql::UxSliByOperationName, feature_category: :vulnerability_management do
  describe '#track' do
    subject(:track) { described_class.new(operation_name).track { :result } }

    before do
      allow(described_class).to receive(:operation_ux_sli_map).and_return('knownOperation' => :test_experience)
    end

    context 'when operation_name is nil' do
      let(:operation_name) { nil }

      it 'does not start a user experience SLI' do
        expect(Labkit::UserExperienceSli).not_to receive(:start)

        track
      end

      it 'returns the value from the block' do
        expect(track).to eq(:result)
      end

      it 'yields control' do
        expect { |block| described_class.new(operation_name).track(&block) }.to yield_control
      end
    end

    context 'when operation_name is unknown' do
      let(:operation_name) { 'unknownOperation' }

      it 'does not start a user experience SLI' do
        expect(Labkit::UserExperienceSli).not_to receive(:start)

        track
      end

      it 'returns the value from the block' do
        expect(track).to eq(:result)
      end

      it 'yields control' do
        expect { |block| described_class.new(operation_name).track(&block) }.to yield_control
      end
    end
  end
end
