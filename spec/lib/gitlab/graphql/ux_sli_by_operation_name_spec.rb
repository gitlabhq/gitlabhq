# frozen_string_literal: true

require 'spec_helper'
require 'labkit/rspec/matchers'

RSpec.describe Gitlab::Graphql::UxSliByOperationName, feature_category: :vulnerability_management do
  describe '#track' do
    subject(:track) { described_class.new(operation_name).track { :result } }

    let(:experience_id) { :test_experience }

    before do
      allow(described_class).to receive(:operation_ux_sli_map).and_return('knownOperation' => experience_id)
    end

    context 'when operation_name is nil' do
      let(:operation_name) { nil }

      it 'does not start a user experience SLI' do
        expect { track }.not_to start_user_experience(experience_id)
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
        expect { track }.not_to start_user_experience(experience_id)
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
