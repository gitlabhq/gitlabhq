# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildPendingState, feature_category: :continuous_integration do
  describe 'associations' do
    it do
      is_expected.to belong_to(:build).class_name('Ci::Build').with_foreign_key(:build_id).inverse_of(:pending_state)
    end
  end

  describe 'validations' do
    subject(:pending_state) { build(:ci_build_pending_state) }

    it { is_expected.to validate_presence_of(:build) }
  end

  describe '#crc32' do
    context 'when checksum does not exist' do
      let(:pending_state) do
        build(:ci_build_pending_state, trace_checksum: nil)
      end

      it 'returns nil' do
        expect(pending_state.crc32).to be_nil
      end
    end

    context 'when checksum is in hexadecimal' do
      let(:pending_state) do
        build(:ci_build_pending_state, trace_checksum: 'crc32:75bcd15')
      end

      it 'returns decimal representation of the checksum' do
        expect(pending_state.crc32).to eq 123456789
      end
    end
  end

  describe 'partitioning' do
    context 'with build' do
      let(:build) { FactoryBot.build(:ci_build, partition_id: ci_testing_partition_id) }
      let(:build_pending_state) { FactoryBot.build(:ci_build_pending_state, build: build) }

      it 'sets partition_id to the current partition value' do
        expect { build_pending_state.valid? }.to change { build_pending_state.partition_id }.to(ci_testing_partition_id)
      end

      context 'when it is already set' do
        let(:build_pending_state) { FactoryBot.build(:ci_build_pending_state, partition_id: 125) }

        it 'does not change the partition_id value' do
          expect { build_pending_state.valid? }.not_to change { build_pending_state.partition_id }
        end
      end
    end

    context 'without build' do
      let(:build_pending_state) { FactoryBot.build(:ci_build_pending_state, build: nil) }

      it { is_expected.to validate_presence_of(:partition_id) }

      it 'does not change the partition_id value' do
        expect { build_pending_state.valid? }.not_to change { build_pending_state.partition_id }
      end
    end
  end

  describe '#set_project_id' do
    it 'sets the project_id before validation' do
      pending_state = create(:ci_build_pending_state)

      expect(pending_state.project_id).to eq(pending_state.build.project_id)
    end

    it 'does not override the project_id if set' do
      existing_project = create(:project)
      pending_state = create(:ci_build_pending_state, project_id: existing_project.id)

      expect(pending_state.project_id).to eq(existing_project.id)
    end
  end
end
