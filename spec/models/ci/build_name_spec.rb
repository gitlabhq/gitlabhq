# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildName, feature_category: :continuous_integration do
  it { is_expected.to belong_to(:build) }

  describe 'validation' do
    it { is_expected.to validate_presence_of(:build) }
    it { is_expected.to validate_presence_of(:name) }
  end

  describe '#name=' do
    it 'truncates name to 255 characters' do
      build_name = described_class.new
      build_name.name = 'A' * 1000
      expect(build_name.name.size).to eq(255)
    end
  end

  describe 'partitioning' do
    context 'with build' do
      let_it_be(:build) { FactoryBot.build(:ci_build, partition_id: ci_testing_partition_id) }
      let_it_be(:build_name) { FactoryBot.build(:ci_build_name, build: build) }

      it 'sets partition_id to the current partition value' do
        expect { build_name.valid? }.to change { build_name.partition_id }.to(ci_testing_partition_id)
      end

      context 'when it is already set' do
        let_it_be(:build_name) { FactoryBot.build(:ci_build_name, partition_id: 125) }

        it 'does not change the partition_id value' do
          expect { build_name.valid? }.not_to change { build_name.partition_id }
        end
      end
    end
  end
end
