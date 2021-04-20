# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Clusters::IntegrationsController do
  include AccessMatchersForController

  shared_examples 'a secure endpoint' do
    it 'is allowed for admin when admin mode enabled', :enable_admin_mode do
      expect { subject }.to be_allowed_for(:admin)
    end

    it 'is denied for admin when admin mode disabled' do
      expect { subject }.to be_denied_for(:admin)
    end

    context 'it is allowed for group maintainers' do
      it { expect { subject }.to be_allowed_for(:owner).of(group) }
      it { expect { subject }.to be_allowed_for(:maintainer).of(group) }
      it { expect { subject }.to be_denied_for(:developer).of(group) }
      it { expect { subject }.to be_denied_for(:reporter).of(group) }
      it { expect { subject }.to be_denied_for(:guest).of(group) }
      it { expect { subject }.to be_denied_for(:user) }
      it { expect { subject }.to be_denied_for(:external) }
    end
  end

  describe 'POST create_or_update' do
    let_it_be(:group) { create(:group) }
    let_it_be(:user) { create(:user) }
    let_it_be(:member) { create(:group_member, user: user, group: group) }

    let(:cluster) { create(:cluster, :group, :provided_by_gcp, groups: [group]) }

    it_behaves_like '#create_or_update action' do
      let(:path) { create_or_update_group_cluster_integration_path(group, cluster) }
      let(:redirect_path) { group_cluster_path(group, cluster, params: { tab: 'integrations' }) }
    end
  end
end
