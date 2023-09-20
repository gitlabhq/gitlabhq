# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ReportedContentEntity, feature_category: :insider_threat do
  let_it_be(:report) { build_stubbed(:abuse_report) }

  let(:entity) do
    described_class.new(report)
  end

  describe '#as_json' do
    subject(:entity_hash) { entity.as_json }

    it 'exposes correct attributes' do
      expect(entity_hash.keys).to match_array([
        :id,
        :global_id,
        :status,
        :message,
        :reported_at,
        :category,
        :type,
        :content,
        :url,
        :screenshot,
        :reporter,
        :update_path,
        :moderate_user_path
      ])
    end

    it 'includes correct value for global_id' do
      allow(Gitlab::GlobalId).to receive(:build).with(report, { id: report.id }).and_return(:mock_global_id)

      expect(entity_hash[:global_id]).to eq 'mock_global_id'
    end

    it 'correctly exposes `reporter`' do
      reporter_hash = entity_hash[:reporter]

      expect(reporter_hash.keys).to match_array([
        :name,
        :username,
        :avatar_url,
        :path
      ])
    end
  end
end
