require 'spec_helper'

describe Gitlab::Verify::Uploads do
  include GitlabVerifyHelpers

  it_behaves_like 'Gitlab::Verify::BatchVerifier subclass' do
    let(:projects) { create_list(:project, 3, :with_avatar) }
    let!(:objects) { projects.flat_map(&:uploads) }
  end

  describe '#run_batches' do
    let(:project) { create(:project, :with_avatar) }
    let(:failures) { collect_failures }
    let(:failure) { failures[upload] }

    let!(:upload) { project.uploads.first }

    it 'passes uploads with the correct file' do
      expect(failures).to eq({})
    end

    it 'fails uploads with a missing file' do
      FileUtils.rm_f(upload.absolute_path)

      expect(failures.keys).to contain_exactly(upload)
      expect(failure).to be_a(Errno::ENOENT)
      expect(failure.to_s).to include(upload.absolute_path)
    end

    it 'fails uploads with a mismatched checksum' do
      upload.update!(checksum: 'something incorrect')

      expect(failures.keys).to contain_exactly(upload)
      expect(failure.to_s).to include('Checksum mismatch')
    end

    it 'fails uploads with a missing precalculated checksum' do
      upload.update!(checksum: '')

      expect(failures.keys).to contain_exactly(upload)
      expect(failure.to_s).to include('Checksum missing')
    end

    context 'with remote files' do
      before do
        stub_uploads_object_storage(AvatarUploader)
      end

      it 'skips uploads in object storage' do
        local_failure = create(:upload)
        create(:upload, :object_storage)

        failures = {}
        described_class.new(batch_size: 10).run_batches { |_, failed| failures.merge!(failed) }

        expect(failures.keys).to contain_exactly(local_failure)
      end
    end
  end
end
