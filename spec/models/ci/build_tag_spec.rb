# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildTag, feature_category: :continuous_integration do
  it { is_expected.to belong_to(:build).optional(false) }
  it { is_expected.to belong_to(:tag).optional(false) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project_id) }
  end

  describe 'partitioning' do
    context 'with build' do
      let_it_be(:build) { FactoryBot.build(:ci_build, partition_id: ci_testing_partition_id) }
      let_it_be(:build_tag) { FactoryBot.build(:ci_build_tag, build: build) }

      it 'sets partition_id to the current partition value' do
        expect { build_tag.valid? }.to change { build_tag.partition_id }.to(ci_testing_partition_id)
      end

      context 'when it is already set' do
        let_it_be(:build_tag) { FactoryBot.build(:ci_build_tag, partition_id: 125) }

        it 'does not change the partition_id value' do
          expect { build_tag.valid? }.not_to change { build_tag.partition_id }
        end
      end
    end
  end
end
