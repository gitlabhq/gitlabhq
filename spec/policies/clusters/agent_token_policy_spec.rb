# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::AgentTokenPolicy do
  let_it_be(:token) { create(:cluster_agent_token) }

  let(:user) { create(:user) }
  let(:policy) { described_class.new(user, token) }
  let(:project) { token.agent.project }

  describe 'rules' do
    context 'when developer' do
      before do
        project.add_developer(user)
      end

      it { expect(policy).to be_disallowed :admin_cluster }
      it { expect(policy).to be_disallowed :read_cluster }
    end

    context 'when maintainer' do
      before do
        project.add_maintainer(user)
      end

      it { expect(policy).to be_allowed :admin_cluster }
      it { expect(policy).to be_allowed :read_cluster }
    end
  end
end
