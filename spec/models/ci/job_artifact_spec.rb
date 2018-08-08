require 'spec_helper'

describe Ci::JobArtifact do
  let(:artifact) { create(:ci_job_artifact, :archive) }

  describe "Associations" do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:job) }
  end

  it { is_expected.to respond_to(:file) }
  it { is_expected.to respond_to(:created_at) }
  it { is_expected.to respond_to(:updated_at) }

  it { is_expected.to delegate_method(:open).to(:file) }
  it { is_expected.to delegate_method(:exists?).to(:file) }

  describe '.test_reports' do
    subject { described_class.test_reports }

    context 'when there is a test report' do
      let!(:artifact) { create(:ci_job_artifact, :junit) }

      it { is_expected.to eq([artifact]) }
    end

    context 'when there are no test reports' do
      let!(:artifact) { create(:ci_job_artifact, :archive) }

      it { is_expected.to be_empty }
    end
  end

  describe 'callbacks' do
    subject { create(:ci_job_artifact, :archive) }

    describe '#schedule_background_upload' do
      context 'when object storage is disabled' do
        before do
          stub_artifacts_object_storage(enabled: false)
        end

        it 'does not schedule the migration' do
          expect(ObjectStorage::BackgroundMoveWorker).not_to receive(:perform_async)

          subject
        end
      end

      context 'when object storage is enabled' do
        context 'when background upload is enabled' do
          before do
            stub_artifacts_object_storage(background_upload: true)
          end

          it 'schedules the model for migration' do
            expect(ObjectStorage::BackgroundMoveWorker).to receive(:perform_async).with('JobArtifactUploader', described_class.name, :file, kind_of(Numeric))

            subject
          end
        end

        context 'when background upload is disabled' do
          before do
            stub_artifacts_object_storage(background_upload: false)
          end

          it 'schedules the model for migration' do
            expect(ObjectStorage::BackgroundMoveWorker).not_to receive(:perform_async)

            subject
          end
        end
      end
    end
  end

  context 'creating the artifact' do
    let(:project) { create(:project) }
    let(:artifact) { create(:ci_job_artifact, :archive, project: project) }

    it 'sets the size from the file size' do
      expect(artifact.size).to eq(106365)
    end

    it 'updates the project statistics' do
      expect { artifact }
        .to change { project.statistics.reload.build_artifacts_size }
        .by(106365)
    end
  end

  context 'updating the artifact file' do
    it 'updates the artifact size' do
      artifact.update!(file: fixture_file_upload('spec/fixtures/dk.png'))
      expect(artifact.size).to eq(1062)
    end

    it 'updates the project statistics' do
      expect { artifact.update!(file: fixture_file_upload('spec/fixtures/dk.png')) }
        .to change { artifact.project.statistics.reload.build_artifacts_size }
        .by(1062 - 106365)
    end
  end

  describe 'validates file format' do
    subject { artifact }

    context 'when archive type with zip format' do
      let(:artifact) { build(:ci_job_artifact, :archive, file_format: :zip) }

      it { is_expected.to be_valid }
    end

    context 'when archive type with gzip format' do
      let(:artifact) { build(:ci_job_artifact, :archive, file_format: :gzip) }

      it { is_expected.not_to be_valid }
    end

    context 'when archive type without format specification' do
      let(:artifact) { build(:ci_job_artifact, :archive, file_format: nil) }

      it { is_expected.not_to be_valid }
    end

    context 'when junit type with zip format' do
      let(:artifact) { build(:ci_job_artifact, :junit, file_format: :zip) }

      it { is_expected.not_to be_valid }
    end

    context 'when junit type with gzip format' do
      let(:artifact) { build(:ci_job_artifact, :junit, file_format: :gzip) }

      it { is_expected.to be_valid }
    end
  end

  describe '#file' do
    subject { artifact.file }

    context 'the uploader api' do
      it { is_expected.to respond_to(:store_dir) }
      it { is_expected.to respond_to(:cache_dir) }
      it { is_expected.to respond_to(:work_dir) }
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
        let(:artifact) { build(:ci_job_artifact, :junit, file: 'junit_with_three_testsuites.xml.gz') }

        it 'iterates blob three times' do
          expect { |b| artifact.each_blob(&b) }.to yield_control.exactly(3).times
        end
      end
    end

    context 'when there are no adapters for the file format' do
      let(:artifact) { build(:ci_job_artifact, :junit, file_format: :zip) }

      it 'raises an error' do
        expect { |b| artifact.each_blob(&b) }.to raise_error(described_class::NotSupportedAdapterError)
      end
    end
  end

  describe '#expire_in' do
    subject { artifact.expire_in }

    it { is_expected.to be_nil }

    context 'when expire_at is specified' do
      let(:expire_at) { Time.now + 7.days }

      before do
        artifact.expire_at = expire_at
      end

      it { is_expected.to be_within(5).of(expire_at - Time.now) }
    end
  end

  describe '#expire_in=' do
    subject { artifact.expire_in }

    it 'when assigning valid duration' do
      artifact.expire_in = '7 days'

      is_expected.to be_within(10).of(7.days.to_i)
    end

    it 'when assigning invalid duration' do
      expect { artifact.expire_in = '7 elephants' }.to raise_error(ChronicDuration::DurationParseError)

      is_expected.to be_nil
    end

    it 'when resetting value' do
      artifact.expire_in = nil

      is_expected.to be_nil
    end

    it 'when setting to 0' do
      artifact.expire_in = '0'

      is_expected.to be_nil
    end
  end

  context 'when destroying the artifact' do
    let(:project) { create(:project, :repository) }
    let(:pipeline) { create(:ci_pipeline, project: project) }
    let!(:build) { create(:ci_build, :artifacts, pipeline: pipeline) }

    it 'updates the project statistics' do
      artifact = build.job_artifacts.first

      expect(ProjectStatistics)
        .to receive(:increment_statistic)
        .and_call_original

      expect { artifact.destroy }
        .to change { project.statistics.reload.build_artifacts_size }
        .by(-106365)
    end

    context 'when it is destroyed from the project level' do
      it 'does not update the project statistics' do
        expect(ProjectStatistics)
          .not_to receive(:increment_statistic)

        project.update(pending_delete: true)
        project.destroy!
      end
    end
  end

  describe 'file is being stored' do
    subject { create(:ci_job_artifact, :archive) }

    context 'when object has nil store' do
      before do
        subject.update_column(:file_store, nil)
        subject.reload
      end

      it 'is stored locally' do
        expect(subject.file_store).to be(nil)
        expect(subject.file).to be_file_storage
        expect(subject.file.object_store).to eq(ObjectStorage::Store::LOCAL)
      end
    end

    context 'when existing object has local store' do
      it 'is stored locally' do
        expect(subject.file_store).to be(ObjectStorage::Store::LOCAL)
        expect(subject.file).to be_file_storage
        expect(subject.file.object_store).to eq(ObjectStorage::Store::LOCAL)
      end
    end

    context 'when direct upload is enabled' do
      before do
        stub_artifacts_object_storage(direct_upload: true)
      end

      context 'when file is stored' do
        it 'is stored remotely' do
          expect(subject.file_store).to eq(ObjectStorage::Store::REMOTE)
          expect(subject.file).not_to be_file_storage
          expect(subject.file.object_store).to eq(ObjectStorage::Store::REMOTE)
        end
      end
    end
  end
end
