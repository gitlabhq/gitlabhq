# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::CleanupLastUsagesWorker, feature_category: :pipeline_composition do
  let_it_be(:component) { create(:ci_catalog_resource_component) }

  subject(:worker) { described_class.new }

  include_examples 'an idempotent worker'

  describe '#perform', :clean_gitlab_redis_shared_state do
    let!(:old_usage) do
      create(:catalog_resource_component_last_usage,
        component: component,
        last_used_date: 31.days.ago.to_date
      )
    end

    let!(:recent_usage) do
      create(:catalog_resource_component_last_usage,
        component: component,
        last_used_date: 29.days.ago.to_date
      )
    end

    let!(:current_usage) do
      create(:catalog_resource_component_last_usage,
        component: component,
        last_used_date: Time.current.to_date
      )
    end

    it 'deletes records older than 30 days' do
      expect { worker.perform }.to change { Ci::Catalog::Resources::Components::LastUsage.count }.by(-1)

      expect(Ci::Catalog::Resources::Components::LastUsage.exists?(old_usage.id)).to be false
      expect(Ci::Catalog::Resources::Components::LastUsage.exists?(recent_usage.id)).to be true
      expect(Ci::Catalog::Resources::Components::LastUsage.exists?(current_usage.id)).to be true
    end
  end
end
