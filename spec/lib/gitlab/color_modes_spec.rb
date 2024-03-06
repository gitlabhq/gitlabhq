# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ColorModes, feature_category: :user_profile do
  describe '.by_id' do
    it 'returns a mode by its ID' do
      expect(described_class.by_id(1).name).to eq 'Light'
      expect(described_class.by_id(2).name).to eq 'Dark (Experiment)'
    end
  end

  describe '.default' do
    it 'use config default' do
      expect(described_class.default.id).to eq 1
    end
  end

  describe '.for_user' do
    it 'returns default when user is nil' do
      expect(described_class.for_user(nil).id).to eq 1
    end

    it "returns user's preferred color mode" do
      user = instance_double(User, color_mode_id: 2)
      expect(described_class.for_user(user).id).to eq 2
    end
  end
end
