# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'clusters/clusters/gcp/_form' do
  let(:admin) { create(:admin) }
  let(:environment) { create(:environment) }
  let(:gcp_cluster) { create(:cluster, :provided_by_gcp) }
  let(:clusterable) { ClusterablePresenter.fabricate(environment.project, current_user: admin) }

  before do
    assign(:environment, environment)
    assign(:gcp_cluster, gcp_cluster)
    allow(view).to receive(:clusterable).and_return(clusterable)
    allow(view).to receive(:url_for).and_return('#')
    allow(view).to receive(:token_in_session).and_return('')
  end

  context 'with all feature flags enabled' do
    it 'has a cloud run checkbox' do
      render

      expect(rendered).to have_selector("input[id='cluster_provider_gcp_attributes_cloud_run']")
    end
  end
end
