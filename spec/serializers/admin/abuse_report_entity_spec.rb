# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admin::AbuseReportEntity, feature_category: :insider_threat do
  include Gitlab::Routing

  let_it_be(:abuse_report) { build_stubbed(:abuse_report, :with_labels) }

  let(:entity) do
    described_class.new(abuse_report)
  end

  describe '#as_json' do
    subject(:entity_hash) { entity.as_json }

    it 'exposes correct attributes' do
      expect(entity_hash.keys).to match_array([
        :category,
        :created_at,
        :updated_at,
        :count,
        :labels,
        :reported_user,
        :reporter,
        :report_path
      ])
    end

    it 'correctly exposes `reported user`' do
      expect(entity_hash[:reported_user].keys).to match_array([:name])
    end

    it 'correctly exposes `reporter`' do
      expect(entity_hash[:reporter].keys).to match_array([:name])
    end

    it 'correctly exposes :report_path' do
      expect(entity_hash[:report_path]).to eq admin_abuse_report_path(abuse_report)
    end

    context 'when abuse_report_labels feature flag is disabled' do
      before do
        stub_feature_flags(abuse_report_labels: false)
      end

      it 'does not expose labels' do
        expect(entity_hash.keys).not_to include(:labels)
      end
    end
  end
end
