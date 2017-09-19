require 'spec_helper'

describe Ci::Artifact do
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:build) }

  it { is_expected.to respond_to(:file) }
  it { is_expected.to respond_to(:created_at) }
  it { is_expected.to respond_to(:updated_at) }
  it { is_expected.to respond_to(:type) }

  let(:artifact) { create(:artifact) }

  describe '#type' do
    it 'defaults to archive' do
      expect(artifact.type).to eq("archive")
    end
  end

  describe '#set_size' do
    it 'sets the size' do
      expect(artifact.size).to eq(106365)
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

  describe '#remove_file' do
    it 'removes the file from the database' do
      artifact.remove_file!

      expect(artifact.file.exists?).to be_falsy
    end
  end

  describe '#exists?' do
    context 'when the artifact file is present' do
      it 'is returns true' do
        expect(artifact.exists?).to be(true)
      end
    end

    context 'when the file has been removed' do
      it 'does not exist' do
        artifact.remove_file!

        expect(artifact.exists?).to be_falsy
      end
    end
  end
end
