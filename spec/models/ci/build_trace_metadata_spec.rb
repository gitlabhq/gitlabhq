# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildTraceMetadata, feature_category: :continuous_integration do
  it { is_expected.to belong_to(:build) }
  it { is_expected.to belong_to(:trace_artifact) }

  it { is_expected.to validate_presence_of(:build) }
  it { is_expected.to validate_presence_of(:archival_attempts) }

  describe '#can_attempt_archival_now?' do
    let(:metadata) do
      build(:ci_build_trace_metadata,
        archival_attempts: archival_attempts,
        last_archival_attempt_at: last_archival_attempt_at)
    end

    subject { metadata.can_attempt_archival_now? }

    context 'when archival_attempts is over the limit' do
      let(:archival_attempts) { described_class::MAX_ATTEMPTS + 1 }
      let(:last_archival_attempt_at) {}

      it { is_expected.to be_falsey }
    end

    context 'when last_archival_attempt_at is not set' do
      let(:archival_attempts) { described_class::MAX_ATTEMPTS }
      let(:last_archival_attempt_at) {}

      it { is_expected.to be_truthy }
    end

    context 'when last_archival_attempt_at is set' do
      let(:archival_attempts) { described_class::MAX_ATTEMPTS }
      let(:last_archival_attempt_at) { 6.days.ago }

      it { is_expected.to be_truthy }
    end

    context 'when last_archival_attempt_at is too close' do
      let(:archival_attempts) { described_class::MAX_ATTEMPTS }
      let(:last_archival_attempt_at) { 1.hour.ago }

      it { is_expected.to be_falsey }
    end
  end

  describe '#archival_attempts_available?' do
    let(:metadata) do
      build(:ci_build_trace_metadata, archival_attempts: archival_attempts)
    end

    subject { metadata.archival_attempts_available? }

    context 'when archival_attempts is over the limit' do
      let(:archival_attempts) { described_class::MAX_ATTEMPTS + 1 }

      it { is_expected.to be_falsey }
    end

    context 'when archival_attempts is at the limit' do
      let(:archival_attempts) { described_class::MAX_ATTEMPTS }

      it { is_expected.to be_truthy }
    end
  end

  describe '#increment_archival_attempts!' do
    let_it_be(:metadata) do
      create(:ci_build_trace_metadata,
        archival_attempts: 2,
        last_archival_attempt_at: 1.day.ago)
    end

    it 'increments the attempts' do
      expect { metadata.increment_archival_attempts! }
        .to change { metadata.reload.archival_attempts }
    end

    it 'updates the last_archival_attempt_at timestamp' do
      expect { metadata.increment_archival_attempts! }
        .to change { metadata.reload.last_archival_attempt_at }
    end
  end

  describe '#track_archival!' do
    let(:trace_artifact) { create(:ci_job_artifact) }
    let(:metadata) { create(:ci_build_trace_metadata) }
    let(:checksum) { SecureRandom.hex }

    it 'stores the artifact id and timestamp' do
      expect(metadata.trace_artifact_id).to be_nil

      metadata.track_archival!(trace_artifact.id, checksum)
      metadata.reload

      expect(metadata.trace_artifact_id).to eq(trace_artifact.id)
      expect(metadata.checksum).to eq(checksum)
      expect(metadata.archived_at).to be_like_time(Time.current)
    end
  end

  describe '.find_or_upsert_for!' do
    let_it_be(:build) { create(:ci_build) }

    subject(:execute) do
      described_class.find_or_upsert_for!(build.id, build.partition_id)
    end

    it 'creates a new record' do
      metadata = execute

      expect(metadata).to be_a(described_class)
      expect(metadata.id).to eq(build.id)
      expect(metadata.archival_attempts).to eq(0)
    end

    context 'with existing records' do
      before do
        create(:ci_build_trace_metadata,
          build: build,
          archival_attempts: described_class::MAX_ATTEMPTS)
      end

      it 'returns the existing record' do
        metadata = execute

        expect(metadata).to be_a(described_class)
        expect(metadata.id).to eq(build.id)
        expect(metadata.archival_attempts).to eq(described_class::MAX_ATTEMPTS)
      end
    end
  end

  describe '#remote_checksum_valid?' do
    using RSpec::Parameterized::TableSyntax

    let(:metadata) do
      build(:ci_build_trace_metadata,
        checksum: checksum,
        remote_checksum: remote_checksum)
    end

    subject { metadata.remote_checksum_valid? }

    where(:checksum, :remote_checksum, :result) do
      nil         | nil         | false
      nil         | 'a'         | false
      'a'         | nil         | false
      'a'         | 'b'         | false
      'b'         | 'a'         | false
      'a'         | 'a'         | true
    end

    with_them do
      it { is_expected.to eq(result) }
    end
  end

  describe 'partitioning' do
    include Ci::PartitioningHelpers

    let_it_be(:pipeline) { create(:ci_pipeline) }
    let_it_be(:build) { create(:ci_build, pipeline: pipeline) }
    let(:new_pipeline) { create(:ci_pipeline) }
    let(:new_build) { create(:ci_build, pipeline: new_pipeline) }
    let(:metadata) { create(:ci_build_trace_metadata, build: new_build) }

    before do
      stub_current_partition_id(ci_testing_partition_id)
    end

    it 'assigns the same partition id as the one that build has' do
      expect(metadata.partition_id).to eq(ci_testing_partition_id)
    end
  end

  describe '#set_project_id' do
    context 'when project_id is not set' do
      let(:metadata) { create(:ci_build_trace_metadata) }

      it 'sets the project_id from the build' do
        expect(metadata.project_id).to eq(metadata.build.project_id)
      end
    end

    context 'when project_id is set' do
      let(:existing_project) { build_stubbed(:project) }
      let(:metadata) { create(:ci_build_trace_metadata, project_id: existing_project.id) }

      it 'does not override the project_id' do
        expect(metadata.project_id).to eq(existing_project.id)
      end
    end
  end
end
