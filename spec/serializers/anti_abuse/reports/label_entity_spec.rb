# frozen_string_literal: true

require "spec_helper"

RSpec.describe AntiAbuse::Reports::LabelEntity, feature_category: :insider_threat do
  let_it_be(:abuse_report_label) { build_stubbed(:abuse_report_label) }

  let(:entity) do
    described_class.new(abuse_report_label)
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
        :updated_at
      ])
    end
  end
end
