# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Integrations::ElasticStack do
  include KubernetesHelpers
  include StubRequests

  describe 'associations' do
    it { is_expected.to belong_to(:cluster).class_name('Clusters::Cluster') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:cluster) }
    it { is_expected.not_to allow_value(nil).for(:enabled) }
  end

  it_behaves_like 'cluster-based #elasticsearch_client', :clusters_integrations_elastic_stack
end
