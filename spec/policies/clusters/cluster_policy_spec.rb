# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::ClusterPolicy, :models, feature_category: :deployment_management do
  let_it_be(:cluster) { create(:cluster, :project, user: nil) }
  let_it_be(:project) { cluster.project }
  let(:policy) { described_class.new(user, cluster) }

  describe 'rules' do
    context 'when developer' do
      let_it_be(:user) { create(:user) }

      before_all do
        project.add_developer(user)
      end

      it { expect(policy).to be_disallowed :update_cluster }
      it { expect(policy).to be_disallowed :admin_cluster }
    end

    context 'when maintainer' do
      let_it_be(:user) { create(:user) }

      before_all do
        project.add_maintainer(user)
      end

      it { expect(policy).to be_allowed :update_cluster }
      it { expect(policy).to be_allowed :admin_cluster }
    end

    context 'group cluster' do
      let_it_be(:cluster) { create(:cluster, :group, user: nil) }
      let_it_be(:group) { cluster.group }
      let_it_be(:project) { create(:project, namespace: group) }

      context 'when group developer' do
        let_it_be(:user) { create(:user) }

        before_all do
          group.add_developer(user)
        end

        it { expect(policy).to be_disallowed :update_cluster }
        it { expect(policy).to be_disallowed :admin_cluster }
      end

      context 'when group maintainer' do
        let_it_be(:user) { create(:user) }

        before_all do
          group.add_maintainer(user)
        end

        it { expect(policy).to be_allowed :update_cluster }
        it { expect(policy).to be_allowed :admin_cluster }
      end

      context 'when project maintainer' do
        let_it_be(:user) { create(:user) }

        before_all do
          project.add_maintainer(user)
        end

        it { expect(policy).to be_disallowed :update_cluster }
        it { expect(policy).to be_disallowed :admin_cluster }
      end

      context 'when project developer' do
        let_it_be(:user) { create(:user) }

        before_all do
          project.add_developer(user)
        end

        it { expect(policy).to be_disallowed :update_cluster }
        it { expect(policy).to be_disallowed :admin_cluster }
      end
    end

    context 'instance cluster' do
      let_it_be(:cluster) { create(:cluster, :instance, user: nil) }
      let_it_be(:user) { create(:user) }

      context 'when user' do
        it { expect(policy).to be_disallowed :update_cluster }
        it { expect(policy).to be_disallowed :admin_cluster }
      end

      context 'when admin' do
        let_it_be(:user) { create(:admin) }

        context 'when admin mode is enabled', :enable_admin_mode do
          it { expect(policy).to be_allowed :update_cluster }
          it { expect(policy).to be_allowed :admin_cluster }
        end

        context 'when admin mode is disabled' do
          it { expect(policy).to be_disallowed :update_cluster }
          it { expect(policy).to be_disallowed :admin_cluster }
        end
      end
    end
  end
end
