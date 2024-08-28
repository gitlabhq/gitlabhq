# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::UrlConfigurationPolicy, feature_category: :deployment_management do
  let_it_be(:url_configuration) { create(:cluster_agent_url_configuration) }

  let(:user) { create(:user) }
  let(:policy) { described_class.new(user, url_configuration) }
  let(:project) { url_configuration.agent.project }

  describe 'rules' do
    context 'when reporter' do
      before do
        project.add_reporter(user)
      end

      it { expect(policy).to be_disallowed :admin_cluster }
      it { expect(policy).to be_disallowed :create_cluster }
      it { expect(policy).to be_disallowed :read_cluster }
    end

    context 'when developer' do
      before do
        project.add_developer(user)
      end

      it { expect(policy).to be_disallowed :admin_cluster }
      it { expect(policy).to be_disallowed :create_cluster }
      it { expect(policy).to be_allowed :read_cluster }
    end

    context 'when maintainer' do
      before do
        project.add_maintainer(user)
      end

      it { expect(policy).to be_allowed :admin_cluster }
      it { expect(policy).to be_allowed :create_cluster }
      it { expect(policy).to be_allowed :read_cluster }
    end
  end
end
