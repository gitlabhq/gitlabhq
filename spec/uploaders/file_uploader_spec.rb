require 'spec_helper'

describe FileUploader do
  let(:uploader) { described_class.new(build_stubbed(:project)) }

  context 'legacy storage' do
    let(:project) { build_stubbed(:project) }

    describe '.absolute_path' do
      it 'returns the correct absolute path by building it dynamically' do
        upload = double(model: project, path: 'secret/foo.jpg')

        dynamic_segment = project.full_path

        expect(described_class.absolute_path(upload))
          .to end_with("#{dynamic_segment}/secret/foo.jpg")
      end
    end

    describe "#store_dir" do
      it "stores in the namespace path" do
        uploader = described_class.new(project)

        expect(uploader.store_dir).to include(project.full_path)
        expect(uploader.store_dir).not_to include("system")
      end
    end
  end

  context 'hashed storage' do
    context 'when rolled out attachments' do
      let(:project) { build_stubbed(:project, :hashed) }

      describe '.absolute_path' do
        it 'returns the correct absolute path by building it dynamically' do
          upload = double(model: project, path: 'secret/foo.jpg')

          dynamic_segment = project.disk_path

          expect(described_class.absolute_path(upload))
            .to end_with("#{dynamic_segment}/secret/foo.jpg")
        end
      end

      describe "#store_dir" do
        it "stores in the namespace path" do
          uploader = described_class.new(project)

          expect(uploader.store_dir).to include(project.disk_path)
          expect(uploader.store_dir).not_to include("system")
        end
      end
    end

    context 'when only repositories are rolled out' do
      let(:project) { build_stubbed(:project, storage_version: Project::HASHED_STORAGE_FEATURES[:repository]) }

      describe '.absolute_path' do
        it 'returns the correct absolute path by building it dynamically' do
          upload = double(model: project, path: 'secret/foo.jpg')

          dynamic_segment = project.full_path

          expect(described_class.absolute_path(upload))
            .to end_with("#{dynamic_segment}/secret/foo.jpg")
        end
      end

      describe "#store_dir" do
        it "stores in the namespace path" do
          uploader = described_class.new(project)

          expect(uploader.store_dir).to include(project.full_path)
          expect(uploader.store_dir).not_to include("system")
        end
      end
    end
  end

  describe 'initialize' do
    it 'generates a secret if none is provided' do
      expect(SecureRandom).to receive(:hex).and_return('secret')

      uploader = described_class.new(double)

      expect(uploader.secret).to eq 'secret'
    end

    it 'accepts a secret parameter' do
      expect(SecureRandom).not_to receive(:hex)

      uploader = described_class.new(double, 'secret')

      expect(uploader.secret).to eq 'secret'
    end
  end

  describe '#move_to_cache' do
    it 'is true' do
      expect(uploader.move_to_cache).to eq(true)
    end
  end

  describe '#move_to_store' do
    it 'is true' do
      expect(uploader.move_to_store).to eq(true)
    end
  end

  describe '#relative_path' do
    it 'removes the leading dynamic path segment' do
      fixture = Rails.root.join('spec', 'fixtures', 'rails_sample.jpg')
      uploader.store!(fixture_file_upload(fixture))

      expect(uploader.relative_path).to match(/\A\h{32}\/rails_sample.jpg\z/)
    end
  end
end
