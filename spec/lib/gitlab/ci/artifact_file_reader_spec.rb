# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::ArtifactFileReader, feature_category: :pipeline_composition do
  let(:job) { create(:ci_build) }
  let(:max_archive_size) { 5.megabytes }
  let(:max_file_size) { 5.megabytes }

  let(:path) { 'generated.yml' } # included in the ci_build_artifacts.zip

  describe '#read' do
    subject { described_class.new(job, max_archive_size: max_archive_size).read(path, max_size: max_file_size) }

    context 'when job has artifacts and metadata' do
      shared_examples 'extracting job artifact archive' do
        it 'returns the content at the path' do
          is_expected.to be_present
          expect(YAML.safe_load(subject).keys).to contain_exactly('rspec', 'time', 'custom')
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
          context "when limits are given to the invocation of the reader" do
            let(:max_archive_size) { 1.kilobytes }
            let(:expected_error) do
              "Artifacts archive for job `#{job.name}` is too large: " \
                "#{ActiveSupport::NumberHelper.number_to_human_size(105.kilobytes)} exceeds maximum of 1 KiB"
            end

            it 'raises an error' do
              expect { subject }.to raise_error(described_class::Error, expected_error)
            end
          end
        end

        context 'when metadata entry shows size greater than the limit' do
          context 'when the limit is set by the value given to the invocation' do
            let(:max_file_size) { 20.megabytes }
            let(:expected_error) do
              "The file `generated.yml` in job `#{job.name}` is too large: " \
                "#{ActiveSupport::NumberHelper.number_to_human_size(21.megabytes)} exceeds maximum of 20 MiB"
            end

            before do
              expect_next_instance_of(Gitlab::Ci::Build::Artifacts::Metadata::Entry) do |entry|
                expect(entry).to receive(:total_size).and_return(21.megabytes)
              end
            end

            it 'raises an error' do
              expect { subject }.to raise_error(described_class::Error, expected_error)
            end
          end
        end
      end

      context 'when job artifact is on local storage' do
        let!(:artifacts) { create(:ci_job_artifact, :archive, job: job) }
        let!(:metadata) { create(:ci_job_artifact, :metadata, job: job) }

        it_behaves_like 'extracting job artifact archive'
      end

      context 'when job artifact is on remote storage' do
        before do
          stub_artifacts_object_storage
          stub_request(:get, %r{https://artifacts.+ci_build_artifacts\.zip})
            .to_return(
              status: 200,
              body: File.open(Rails.root.join('spec/fixtures/ci_build_artifacts.zip')),
              headers: {}
            )
          stub_request(:get, %r{https://artifacts.+ci_build_artifacts_metadata})
            .to_return(
              status: 200,
              body: File.open(Rails.root.join('spec/fixtures/ci_build_artifacts_metadata.gz')),
              headers: {}
            )
        end

        let!(:artifacts) { create(:ci_job_artifact, :archive, :remote_store, job: job) }
        let!(:metadata) { create(:ci_job_artifact, :metadata, :remote_store, job: job) }

        it_behaves_like 'extracting job artifact archive'
      end

      context 'when extracting job artifact raises entry size error' do
        let!(:artifacts) { create(:ci_job_artifact, :archive, job: job) }
        let!(:metadata) { create(:ci_job_artifact, :metadata, job: job) }

        before do
          allow_next_instance_of(SafeZip::Extract, anything) do |extractor|
            allow(extractor).to receive(:extract).and_raise(SafeZip::Extract::EntrySizeError)
          end
        end

        it 'raises an error' do
          expected_error = "Path `#{path}` has invalid size in the zip!"

          expect { subject }.to raise_error(described_class::Error, expected_error)
        end
      end
    end

    context 'when job does not have metadata artifacts' do
      let!(:artifacts) { create(:ci_job_artifact, :archive, job: job) }
      let(:expected_error) do
        "Job `#{job.name}` (#{job.id}) has missing artifacts metadata and cannot be extracted!"
      end

      it 'raises an error' do
        expect { subject }.to raise_error(described_class::Error, expected_error)
      end
    end

    context 'when job does not have artifacts' do
      it 'raises an Error' do
        expect { subject }.to raise_error(described_class::Error,
          "Job `#{job.name}` (#{job.id}) does not have artifacts")
      end
    end
  end
end
