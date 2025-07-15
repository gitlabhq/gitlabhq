# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HookData::MilestoneBuilder, feature_category: :webhooks do
  let_it_be(:milestone) { create(:milestone) }

  let(:builder) { described_class.new(milestone) }

  describe '#build' do
    subject(:data) { builder.build }

    it 'includes safe attributes' do
      expect(data.keys).to match_array(described_class::SAFE_HOOK_ATTRIBUTES.map(&:to_s))
    end

    it 'returns indifferent access hash' do
      expect(data).to be_a(ActiveSupport::HashWithIndifferentAccess)
    end

    it 'includes correct milestone data' do
      expect(data['id']).to eq(milestone.id)
      expect(data['iid']).to eq(milestone.iid)
      expect(data['title']).to eq(milestone.title)
      expect(data['state']).to eq(milestone.state)
      expect(data['project_id']).to eq(milestone.project_id)
    end
  end
end
