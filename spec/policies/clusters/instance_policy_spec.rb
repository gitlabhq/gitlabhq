# frozen_string_literal: true

require 'spec_helper'

describe Clusters::InstancePolicy do
  let(:cluster) { create(:cluster, :instance) }
  let(:user) { create(:user) }
  let(:policy) { described_class.new(user, cluster) }

  describe 'rules' do
    context 'when user' do
      it { expect(policy).to be_disallowed :update_cluster }
      it { expect(policy).to be_disallowed :admin_cluster }
    end

    context 'when admin' do
      let(:user) { create(:admin) }

      it { expect(policy).to be_allowed :update_cluster }
      it { expect(policy).to be_allowed :admin_cluster }
    end
  end
end
