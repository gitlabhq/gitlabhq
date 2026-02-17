# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::TypesFramework::SystemDefined::Definitions::Issue, feature_category: :team_planning do
  describe '.supports_move_action?' do
    it 'returns true' do
      expect(described_class.supports_move_action?).to be(true)
    end
  end

  describe '.filterable?' do
    it 'returns true' do
      expect(described_class.filterable?).to be(true)
    end
  end
end
