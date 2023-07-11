# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DesignManagement::GenerateImageVersionsService, feature_category: :design_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:version) { create(:design, :with_lfs_file, issue: issue).versions.first }
  let_it_be(:action) { version.actions.first }

  describe '#execute' do
    it 'generates the image' do
      expect { described_class.new(version).execute }
        .to change { action.reload.image_v432x230.file }
        .from(nil).to(CarrierWave::SanitizedFile)
    end

    it 'skips generating image versions if the mime type is not allowlisted' do
      stub_const('DesignManagement::DesignV432x230Uploader::MIME_TYPE_ALLOWLIST', [])

      described_class.new(version).execute

      expect(action.reload.image_v432x230.file).to eq(nil)
    end

    it 'skips generating image versions if the design file size is too large' do
      stub_const("#{described_class.name}::MAX_DESIGN_SIZE", 1.byte)

      described_class.new(version).execute

      expect(action.reload.image_v432x230.file).to eq(nil)
    end

    it 'returns the status' do
      result = described_class.new(version).execute

      expect(result[:status]).to eq(:success)
    end

    it 'returns the version' do
      result = described_class.new(version).execute

      expect(result[:version]).to eq(version)
    end

    it 'logs if the raw image cannot be found' do
      version.designs.first.update!(filename: 'foo.png')

      expect(Gitlab::AppLogger).to receive(:error).with("No design file found for Action: #{action.id}")

      described_class.new(version).execute
    end

    context 'when an error is encountered when generating the image versions' do
      context "CarrierWave::IntegrityError" do
        before do
          expect_next_instance_of(DesignManagement::DesignV432x230Uploader) do |uploader|
            expect(uploader).to receive(:cache!).and_raise(CarrierWave::IntegrityError, 'foo')
          end
        end

        it 'logs the exception' do
          expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
            instance_of(CarrierWave::IntegrityError),
            project_id: project.id, version_id: version.id, design_id: version.designs.first.id
          )

          described_class.new(version).execute
        end

        it 'logs the error' do
          expect(Gitlab::AppLogger).to receive(:error).with('foo')

          described_class.new(version).execute
        end
      end

      context "CarrierWave::UploadError" do
        before do
          expect_next_instance_of(DesignManagement::DesignV432x230Uploader) do |uploader|
            expect(uploader).to receive(:cache!).and_raise(CarrierWave::UploadError, 'foo')
          end
        end

        it 'logs the error' do
          expect(Gitlab::AppLogger).to receive(:error).with('foo')

          described_class.new(version).execute
        end

        it 'tracks the error' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
            instance_of(CarrierWave::UploadError),
            project_id: project.id, version_id: version.id, design_id: version.designs.first.id
          )

          described_class.new(version).execute
        end
      end
    end
  end
end
