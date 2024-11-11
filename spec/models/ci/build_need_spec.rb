# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildNeed, :model, feature_category: :continuous_integration do
  let(:build_need) { build(:ci_build_need) }

  it { is_expected.to belong_to(:build).class_name('Ci::Processable') }

  it { is_expected.to validate_presence_of(:build) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:project_id) }
  it { is_expected.to validate_length_of(:name).is_at_most(255) }

  describe 'scopes' do
    describe '.scoped_build' do
      subject(:scoped_build) { described_class.scoped_build }

      it 'includes partition_id filter' do
        expect(scoped_build.where_values_hash).to match(a_hash_including('partition_id'))
      end
    end

    describe '.artifacts' do
      let_it_be(:with_artifacts)    { create(:ci_build_need, artifacts: true) }
      let_it_be(:without_artifacts) { create(:ci_build_need, artifacts: false) }

      it { expect(described_class.artifacts).to contain_exactly(with_artifacts) }
    end
  end

  describe 'BulkInsertSafe' do
    let(:ci_build) { build(:ci_build) }

    it "bulk inserts from Ci::Build model" do
      ci_build.needs_attributes = [
        { name: "build", artifacts: true },
        { name: "build2", artifacts: true },
        { name: "build3", artifacts: true }
      ]

      expect(described_class).to receive(:bulk_insert!).and_call_original

      BulkInsertableAssociations.with_bulk_insert do
        ci_build.save!
      end
    end
  end

  describe 'partitioning' do
    context 'with build' do
      let(:build) { FactoryBot.build(:ci_build, partition_id: ci_testing_partition_id) }
      let(:build_need) { FactoryBot.build(:ci_build_need, build: build) }

      it 'sets partition_id to the current partition value' do
        expect { build_need.valid? }.to change { build_need.partition_id }.to(ci_testing_partition_id)
      end

      context 'when it is already set' do
        let(:build_need) { FactoryBot.build(:ci_build_need, partition_id: 125) }

        it 'does not change the partition_id value' do
          expect { build_need.valid? }.not_to change { build_need.partition_id }
        end
      end
    end

    context 'without build' do
      let(:build_need) { FactoryBot.build(:ci_build_need, build: nil, project_id: nil) }

      it { is_expected.to validate_presence_of(:partition_id) }

      it 'does not change the partition_id value' do
        expect { build_need.valid? }.not_to change { build_need.partition_id }
      end
    end

    context 'when using bulk_insert' do
      include Ci::PartitioningHelpers

      let(:new_pipeline) { create(:ci_pipeline) }
      let(:ci_build) { build(:ci_build, pipeline: new_pipeline) }

      before do
        stub_current_partition_id(ci_testing_partition_id)
      end

      it 'creates build needs successfully', :aggregate_failures do
        ci_build.needs_attributes = [
          { name: "build", artifacts: true },
          { name: "build2", artifacts: true },
          { name: "build3", artifacts: true }
        ]

        expect(described_class).to receive(:bulk_insert!).and_call_original

        BulkInsertableAssociations.with_bulk_insert do
          ci_build.save!
        end

        expect(described_class.count).to eq(3)
        expect(described_class.first.partition_id).to eq(ci_testing_partition_id)
        expect(described_class.second.partition_id).to eq(ci_testing_partition_id)
      end
    end
  end
end
