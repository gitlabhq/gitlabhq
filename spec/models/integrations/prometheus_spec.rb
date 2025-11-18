# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Prometheus, feature_category: :integrations do
  let_it_be(:integration) { create(:prometheus_integration) }

  it { is_expected.to belong_to(:project) }

  it 'can be found by global id' do
    expect(GitlabSchema.find_by_gid(integration.to_global_id).sync).to eq(integration)
  end

  describe '.title' do
    subject { integration.title }

    it { is_expected.to eq('Prometheus') }
  end

  describe '.description' do
    subject { integration.description }

    it { is_expected.to be_a String }
  end

  describe '.to_param' do
    subject { integration.to_param }

    it { is_expected.to eq('prometheus') }
  end
end
