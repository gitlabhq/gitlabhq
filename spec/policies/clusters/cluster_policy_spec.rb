# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::ClusterPolicy, :models do
  let(:cluster) { create(:cluster, :project) }
  let(:project) { cluster.project }
  let(:user) { create(:user) }
  let(:policy) { described_class.new(user, cluster) }

  describe 'rules' do
    context 'when developer' do
      before do
        project.add_developer(user)
      end

      it { expect(policy).to be_disallowed :update_cluster }
      it { expect(policy).to be_disallowed :admin_cluster }
    end

    context 'when maintainer' do
      before do
        project.add_maintainer(user)
      end

      it { expect(policy).to be_allowed :update_cluster }
      it { expect(policy).to be_allowed :admin_cluster }
    end

    context 'group cluster' do
      let(:cluster) { create(:cluster, :group) }
      let(:group) { cluster.group }
      let(:project) { create(:project, namespace: group) }

      context 'when group developer' do
        before do
          group.add_developer(user)
        end

        it { expect(policy).to be_disallowed :update_cluster }
        it { expect(policy).to be_disallowed :admin_cluster }
      end

      context 'when group maintainer' do
        before do
          group.add_maintainer(user)
        end

        it { expect(policy).to be_allowed :update_cluster }
        it { expect(policy).to be_allowed :admin_cluster }
      end

      context 'when project maintainer' do
        before do
          project.add_maintainer(user)
        end

        it { expect(policy).to be_disallowed :update_cluster }
        it { expect(policy).to be_disallowed :admin_cluster }
      end

      context 'when project developer' do
        before do
          project.add_developer(user)
        end

        it { expect(policy).to be_disallowed :update_cluster }
        it { expect(policy).to be_disallowed :admin_cluster }
      end
    end

    context 'instance cluster' do
      let(:cluster) { create(:cluster, :instance) }

      context 'when user' do
        it { expect(policy).to be_disallowed :update_cluster }
        it { expect(policy).to be_disallowed :admin_cluster }
      end

      context 'when admin' do
        let(:user) { create(:admin) }

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
