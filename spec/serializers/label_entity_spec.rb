# frozen_string_literal: true

require "spec_helper"

RSpec.describe LabelEntity, feature_category: :team_planning do
  let_it_be(:label) { build_stubbed(:label) }

  let(:entity) do
    described_class.new(label)
  end

  describe '#as_json' do
    subject(:entity_hash) { entity.as_json }

    it 'exposes correct attributes' do
      expect(entity_hash.keys).to match_array([
        :id,
        :title,
        :color,
        :description,
        :text_color,
        :created_at,
        :updated_at,
        :group_id,
        :project_id,
        :template
      ])
    end
  end
end
