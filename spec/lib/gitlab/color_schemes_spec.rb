require 'spec_helper'

describe Gitlab::ColorSchemes do
  describe '.body_classes' do
    it 'returns a space-separated list of class names' do
      css = described_class.body_classes

      expect(css).to include('white')
      expect(css).to include(' solarized-light ')
      expect(css).to include(' monokai')
    end
  end

  describe '.by_id' do
    it 'returns a scheme by its ID' do
      expect(described_class.by_id(1).name).to eq 'White'
      expect(described_class.by_id(4).name).to eq 'Solarized Dark'
    end
  end

  describe '.default' do
    it 'returns the default scheme' do
      expect(described_class.default.id).to eq 1
    end
  end

  describe '.each' do
    it 'passes the block to the SCHEMES Array' do
      ids = []
      described_class.each { |scheme| ids << scheme.id }
      expect(ids).not_to be_empty
    end
  end

  describe '.for_user' do
    it 'returns default when user is nil' do
      expect(described_class.for_user(nil).id).to eq 1
    end

    it "returns user's preferred color scheme" do
      user = double(color_scheme_id: 5)
      expect(described_class.for_user(user).id).to eq 5
    end
  end
end
