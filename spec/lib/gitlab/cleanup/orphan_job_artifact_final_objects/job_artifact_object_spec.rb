# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cleanup::OrphanJobArtifactFinalObjects::JobArtifactObject, :clean_gitlab_redis_shared_state, feature_category: :build_artifacts do
  let(:job_artifact_object) do
    described_class.new(
      fog_file,
      bucket_prefix: bucket_prefix
    )
  end

  # rubocop:disable RSpec/VerifiedDoubles -- For some reason it can't see Fog::AWS::Storage::File
  let(:fog_file) { double(key: fog_file_key, content_length: 145) }
  # rubocop:enable RSpec/VerifiedDoubles

  let(:fog_file_key) { 'aaa/bbb/123' }
  let(:bucket_prefix) { nil }

  describe '#path' do
    subject { job_artifact_object.path }

    it { is_expected.to eq(fog_file.key) }
  end

  describe '#size' do
    subject { job_artifact_object.size }

    it { is_expected.to eq(fog_file.content_length) }
  end

  describe '#in_final_location?' do
    subject { job_artifact_object.in_final_location? }

    context 'when path has @final in it' do
      let(:fog_file_key) { 'aaa/bbb/@final/123/ccc' }

      it { is_expected.to eq(true) }
    end

    context 'when path has no @final in it' do
      let(:fog_file_key) { 'aaa/bbb/ccc' }

      it { is_expected.to eq(false) }
    end
  end

  describe '#orphan?' do
    shared_examples_for 'identifying orphan object' do
      let(:artifact_final_path) { 'aaa/@final/bbb' }
      let(:fog_file_key) { File.join([bucket_prefix, artifact_final_path].compact) }

      subject { job_artifact_object.orphan? }

      context 'when there is job artifact record with a file_final_path that matches the object path' do
        before do
          # We don't store the bucket_prefix if ever in the file_final_path
          create(:ci_job_artifact, file_final_path: artifact_final_path)
        end

        it { is_expected.to eq(false) }
      end

      context 'when there are no job artifact records with a file_final_path that matches the object path' do
        context 'and there is a pending direct upload entry that matches the object path' do
          before do
            # We don't store the bucket_prefix if ever in the pending direct upload entry
            ObjectStorage::PendingDirectUpload.prepare(:artifacts, artifact_final_path)
          end

          it { is_expected.to eq(false) }
        end

        context 'and there are no pending direct upload entries that match the object path' do
          it { is_expected.to eq(true) }
        end
      end
    end

    context 'when bucket prefix is not present' do
      it_behaves_like 'identifying orphan object'
    end

    context 'when bucket prefix is present' do
      let(:bucket_prefix) { 'my/prefix' }

      it_behaves_like 'identifying orphan object'
    end
  end
end
