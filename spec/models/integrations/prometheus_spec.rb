# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Prometheus, feature_category: :integrations do
  let_it_be(:integration) { create(:prometheus_integration) }

  it { is_expected.to belong_to(:project) }

  it 'can be found by global id' do
    expect(GitlabSchema.find_by_gid(integration.to_global_id).sync).to eq(integration)
  end
end
