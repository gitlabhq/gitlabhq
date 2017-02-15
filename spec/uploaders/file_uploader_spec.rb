require 'spec_helper'

describe FileUploader do
  let(:uploader) { described_class.new(build_stubbed(:empty_project)) }

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
end
