# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::SystemDefined::RelatedLinkRestriction, feature_category: :team_planning do
  describe 'validations' do
    it 'has the correct minimal structure for each item' do
      expect(described_class::ITEMS).to all(include(:id, :source_type_id, :target_type_id, :link_type))
    end
  end
end
