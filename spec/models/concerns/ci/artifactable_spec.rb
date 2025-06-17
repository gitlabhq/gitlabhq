# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Artifactable do
  let(:ci_job_artifact) { build(:ci_job_artifact) }

  describe 'artifact properties are included' do
    context 'when enum is defined' do
      subject { ci_job_artifact }

      it { is_expected.to define_enum_for(:file_format).with_values(raw: 1, zip: 2, gzip: 3).with_suffix }
    end

    context 'when const is defined' do
      subject { ci_job_artifact.class }

      it { is_expected.to be_const_defined(:FILE_FORMAT_ADAPTERS) }
    end
  end

  describe '#each_blob' do
    context 'when file format is gzip' do
      context 'when gzip file contains one file' do
        let(:artifact) { build(:ci_job_artifact, :junit) }

        it 'iterates blob once' do
          expect { |b| artifact.each_blob(&b) }.to yield_control.once
        end
      end

      context 'when gzip file contains three files' do
        let(:artifact) { build(:ci_job_artifact, :junit_with_three_testsuites) }

        it 'iterates blob three times' do
          expect { |b| artifact.each_blob(&b) }.to yield_control.exactly(3).times
        end
      end

      context 'when decompressed artifact size validator fails' do
        let(:artifact) { build(:ci_job_artifact, :junit) }

        before do
          allow_next_instance_of(Gitlab::Ci::DecompressedGzipSizeValidator) do |instance|
            allow(instance).to receive(:valid?).and_return(false)
          end
        end

        it 'fails on blob' do
          expect { |b| artifact.each_blob(&b) }
            .to raise_error(::Gitlab::Ci::Artifacts::DecompressedArtifactSizeValidator::FileDecompressionError)
        end
      end
    end

    context 'when file format is raw' do
      let(:artifact) { build(:ci_job_artifact, :codequality, file_format: :raw) }

      it 'iterates blob once' do
        expect { |b| artifact.each_blob(&b) }.to yield_control.once
      end
    end

    context 'when there are no adapters for the file format' do
      let(:artifact) { build(:ci_job_artifact, :junit, file_format: :zip) }

      it 'raises an error' do
        expect { |b| artifact.each_blob(&b) }.to raise_error(described_class::NotSupportedAdapterError)
      end
    end

    context 'pushes artifact_size to application context' do
      let(:artifact) { create(:ci_job_artifact, :junit) }

      it 'logs artifact size', :aggregate_failures do
        expect { |b| artifact.each_blob(&b) }.to yield_control.once
        expect(Gitlab::ApplicationContext.current).to include("meta.artifact_size" => artifact.size)
      end
    end
  end

  context 'ActiveRecord scopes' do
    let_it_be(:recently_expired_artifact) { create(:ci_job_artifact, expire_at: 1.day.ago) }
    let_it_be(:later_expired_artifact) { create(:ci_job_artifact, expire_at: 2.days.ago) }
    let_it_be(:not_expired_artifact) { create(:ci_job_artifact, expire_at: 1.day.from_now) }

    describe '.expired_before' do
      it 'returns expired artifacts' do
        expect(Ci::JobArtifact.expired_before(1.hour.ago))
          .to match_array([recently_expired_artifact, later_expired_artifact])
      end
    end

    describe '.expired' do
      it 'returns all expired artifacts' do
        expect(Ci::JobArtifact.expired).to contain_exactly(recently_expired_artifact, later_expired_artifact)
      end
    end

    describe '.project_id_in' do
      context 'when artifacts belongs to projects' do
        let(:project_ids) { [recently_expired_artifact.project.id, not_expired_artifact.project.id, non_existing_record_id] }

        it 'returns artifacts belonging to projects' do
          expect(Ci::JobArtifact.project_id_in(project_ids)).to contain_exactly(recently_expired_artifact, not_expired_artifact)
        end
      end
    end
  end
end
