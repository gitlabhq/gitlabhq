# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::ArtifactFileReader do
  let(:job) { create(:ci_build) }
  let(:path) { 'generated.yml' } # included in the ci_build_artifacts.zip

  describe '#read' do
    subject { described_class.new(job).read(path) }

    context 'when job has artifacts and metadata' do
      let!(:artifacts) { create(:ci_job_artifact, :archive, job: job) }
      let!(:metadata) { create(:ci_job_artifact, :metadata, job: job) }

      it 'returns the content at the path' do
        is_expected.to be_present
        expect(YAML.safe_load(subject).keys).to contain_exactly('rspec', 'time', 'custom')
      end

      context 'when FF ci_new_artifact_file_reader is disabled' do
        before do
          stub_feature_flags(ci_new_artifact_file_reader: false)
        end

        it 'returns the content at the path' do
          is_expected.to be_present
          expect(YAML.safe_load(subject).keys).to contain_exactly('rspec', 'time', 'custom')
        end
      end

      context 'when path does not exist' do
        let(:path) { 'file/does/not/exist.txt' }
        let(:expected_error) do
          "Path `#{path}` does not exist inside the `#{job.name}` artifacts archive!"
        end

        it 'raises an error' do
          expect { subject }.to raise_error(described_class::Error, expected_error)
        end
      end

      context 'when path points to a directory' do
        let(:path) { 'other_artifacts_0.1.2' }
        let(:expected_error) do
          "Path `#{path}` was expected to be a file but it was a directory!"
        end

        it 'raises an error' do
          expect { subject }.to raise_error(described_class::Error, expected_error)
        end
      end

      context 'when path is nested' do
        # path exists in ci_build_artifacts.zip
        let(:path) { 'other_artifacts_0.1.2/doc_sample.txt' }

        it 'returns the content at the nested path' do
          is_expected.to be_present
        end
      end

      context 'when artifact archive size is greater than the limit' do
        let(:expected_error) do
          "Artifacts archive for job `#{job.name}` is too large: max 1 KB"
        end

        before do
          stub_const("#{described_class}::MAX_ARCHIVE_SIZE", 1.kilobyte)
        end

        it 'raises an error' do
          expect { subject }.to raise_error(described_class::Error, expected_error)
        end
      end

      context 'when metadata entry shows size greater than the limit' do
        let(:expected_error) do
          "Artifacts archive for job `#{job.name}` is too large: max 5 MB"
        end

        before do
          expect_next_instance_of(Gitlab::Ci::Build::Artifacts::Metadata::Entry) do |entry|
            expect(entry).to receive(:total_size).and_return(10.megabytes)
          end
        end

        it 'raises an error' do
          expect { subject }.to raise_error(described_class::Error, expected_error)
        end
      end
    end

    context 'when job does not have metadata artifacts' do
      let!(:artifacts) { create(:ci_job_artifact, :archive, job: job) }
      let(:expected_error) do
        "Job `#{job.name}` has missing artifacts metadata and cannot be extracted!"
      end

      it 'raises an error' do
        expect { subject }.to raise_error(described_class::Error, expected_error)
      end
    end

    context 'when job does not have artifacts' do
      it 'raises ArgumentError' do
        expect { subject }.to raise_error(ArgumentError, 'Job does not have artifacts')
      end
    end
  end
end
