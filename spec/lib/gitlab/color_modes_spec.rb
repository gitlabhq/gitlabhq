# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ColorModes, feature_category: :user_profile do
  describe '.by_id' do
    it 'returns a mode by its ID' do
      expect(described_class.by_id(Gitlab::ColorModes::APPLICATION_LIGHT).name).to eq 'Light'
      expect(described_class.by_id(Gitlab::ColorModes::APPLICATION_DARK).name).to eq 'Dark'
      expect(described_class.by_id(Gitlab::ColorModes::APPLICATION_SYSTEM).name).to eq 'Auto'
    end
  end

  describe '.default' do
    it 'use config default' do
      expect(described_class.default.id).to eq Gitlab::ColorModes::APPLICATION_DEFAULT
    end
  end

  describe '.for_user' do
    it 'returns default when user is nil' do
      expect(described_class.for_user(nil).id).to eq Gitlab::ColorModes::APPLICATION_DEFAULT
    end

    it 'returns color mode', :aggregate_failures do
      # Test Light mode
      light_user = instance_double(User, color_mode_id: Gitlab::ColorModes::APPLICATION_LIGHT)
      expect(described_class.for_user(light_user).id).to eq Gitlab::ColorModes::APPLICATION_LIGHT
      expect(described_class.for_user(light_user).name).to eq 'Light'

      # Test Dark mode
      dark_user = instance_double(User, color_mode_id: Gitlab::ColorModes::APPLICATION_DARK)
      expect(described_class.for_user(dark_user).id).to eq Gitlab::ColorModes::APPLICATION_DARK
      expect(described_class.for_user(dark_user).name).to eq 'Dark'

      # Test Auto mode
      auto_user = instance_double(User, color_mode_id: Gitlab::ColorModes::APPLICATION_SYSTEM)
      expect(described_class.for_user(auto_user).id).to eq Gitlab::ColorModes::APPLICATION_SYSTEM
      expect(described_class.for_user(auto_user).name).to eq 'Auto'
    end
  end
end
