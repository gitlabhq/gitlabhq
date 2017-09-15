require 'spec_helper'

describe Gitlab::Themes, lib: true do
  describe '.body_classes' do
    it 'returns a space-separated list of class names' do
      css = described_class.body_classes

      expect(css).to include('ui_indigo')
      expect(css).to include(' ui_dark ')
      expect(css).to include(' ui_blue')
    end
  end

  describe '.by_id' do
    it 'returns a Theme by its ID' do
      expect(described_class.by_id(1).name).to eq 'Indigo'
      expect(described_class.by_id(3).name).to eq 'Light'
    end
  end

  describe '.default' do
    it 'returns the default application theme' do
      allow(described_class).to receive(:default_id).and_return(2)
      expect(described_class.default.id).to eq 2
    end

    it 'prevents an infinite loop when configuration default is invalid' do
      default = described_class::APPLICATION_DEFAULT
      themes  = described_class::THEMES

      config = double(default_theme: 0).as_null_object
      allow(Gitlab).to receive(:config).and_return(config)
      expect(described_class.default.id).to eq default

      config = double(default_theme: themes.size + 5).as_null_object
      allow(Gitlab).to receive(:config).and_return(config)
      expect(described_class.default.id).to eq default
    end
  end

  describe '.each' do
    it 'passes the block to the THEMES Array' do
      ids = []
      described_class.each { |theme| ids << theme.id }
      expect(ids).not_to be_empty
    end
  end
end
