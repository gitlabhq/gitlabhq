# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Clusters::IntegrationsController do
  include AccessMatchersForController

  shared_examples 'a secure endpoint' do
    it 'is allowed for admin when admin mode enabled', :enable_admin_mode do
      expect { subject }.to be_allowed_for(:admin)
    end

    it 'is denied for admin when admin mode disabled' do
      expect { subject }.to be_denied_for(:admin)
    end

    context 'it is allowed for project maintainers' do
      it { expect { subject }.to be_allowed_for(:owner).of(project) }
      it { expect { subject }.to be_allowed_for(:maintainer).of(project) }
      it { expect { subject }.to be_denied_for(:developer).of(project) }
      it { expect { subject }.to be_denied_for(:reporter).of(project) }
      it { expect { subject }.to be_denied_for(:guest).of(project) }
      it { expect { subject }.to be_denied_for(:user) }
      it { expect { subject }.to be_denied_for(:external) }
    end
  end

  describe 'POST create_or_update' do
    let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
    let(:project) { cluster.project }
    let(:user) { project.owner }

    it_behaves_like '#create_or_update action' do
      let(:path) { create_or_update_project_cluster_integration_path(project, cluster) }
      let(:redirect_path) { project_cluster_path(project, cluster, params: { tab: 'integrations' }) }
    end
  end
end
