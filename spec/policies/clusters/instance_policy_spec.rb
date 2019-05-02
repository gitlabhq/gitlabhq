# frozen_string_literal: true

require 'spec_helper'

describe Clusters::InstancePolicy do
  let(:user) { create(:user) }
  let(:policy) { described_class.new(user, Clusters::Instance.new) }

  describe 'rules' do
    context 'when user' do
      it { expect(policy).to be_disallowed :read_cluster }
      it { expect(policy).to be_disallowed :update_cluster }
      it { expect(policy).to be_disallowed :admin_cluster }
    end

    context 'when admin' do
      let(:user) { create(:admin) }

      context 'with instance_level_clusters enabled' do
        it { expect(policy).to be_allowed :read_cluster }
        it { expect(policy).to be_allowed :update_cluster }
        it { expect(policy).to be_allowed :admin_cluster }
      end

      context 'with instance_level_clusters disabled' do
        before do
          stub_feature_flags(instance_clusters: false)
        end

        it { expect(policy).to be_disallowed :read_cluster }
        it { expect(policy).to be_disallowed :update_cluster }
        it { expect(policy).to be_disallowed :admin_cluster }
      end
    end
  end
end
