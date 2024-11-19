# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Themes, :lib do
  describe '.body_classes' do
    it 'returns a space-separated list of class names' do
      css = described_class.body_classes

      expect(css).to include('ui-indigo')
      expect(css).to include('ui-gray')
      expect(css).to include('ui-blue')
    end
  end

  describe '.by_id' do
    it 'returns a Theme by its ID' do
      expect(described_class.by_id(1).name).to eq 'Indigo'
      expect(described_class.by_id(3).name).to eq 'Neutral'
    end
  end

  describe '.default' do
    it 'returns the default application theme' do
      allow(described_class).to receive(:default_id).and_return(2)
      expect(described_class.default.id).to eq 2
    end

    it 'prevents an infinite loop when configuration default is invalid',
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/450515' do
      default = described_class::APPLICATION_DEFAULT
      themes  = described_class.available_themes

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

  describe '.valid_ids' do
    it 'returns array of available_themes ids with DEPRECATED_DARK_THEME_ID' do
      expect(described_class.valid_ids).to match_array [1, 6, 4, 7, 5, 8, 9, 10, 2, 3, 11]
    end
  end
end
