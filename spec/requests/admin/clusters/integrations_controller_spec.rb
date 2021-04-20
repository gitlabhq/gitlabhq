# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::Clusters::IntegrationsController, :enable_admin_mode do
  include AccessMatchersForController

  shared_examples 'a secure endpoint' do
    context 'it is allowed for admins only' do
      it { expect { subject }.to be_allowed_for(:admin) }
      it { expect { subject }.to be_denied_for(:user) }
      it { expect { subject }.to be_denied_for(:external) }
    end
  end

  describe 'POST create_or_update' do
    let(:cluster) { create(:cluster, :instance, :provided_by_gcp) }
    let(:user) { create(:admin) }

    it_behaves_like '#create_or_update action' do
      let(:path) { create_or_update_admin_cluster_integration_path(cluster) }
      let(:redirect_path) { admin_cluster_path(cluster, params: { tab: 'integrations' }) }
    end
  end
end
