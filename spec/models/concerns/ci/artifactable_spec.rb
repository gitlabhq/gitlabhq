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
      it 'returns a limited number of expired artifacts' do
        expect(Ci::JobArtifact.expired(1).order_id_asc).to eq([recently_expired_artifact])
      end
    end

    describe '.with_files_stored_locally' do
      it 'returns artifacts stored locally' do
        expect(Ci::JobArtifact.with_files_stored_locally).to contain_exactly(recently_expired_artifact, later_expired_artifact, not_expired_artifact)
      end
    end

    describe '.with_files_stored_remotely' do
      let(:remote_artifact) { create(:ci_job_artifact, :remote_store) }

      before do
        stub_artifacts_object_storage
      end

      it 'returns artifacts stored remotely' do
        expect(Ci::JobArtifact.with_files_stored_remotely).to contain_exactly(remote_artifact)
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
