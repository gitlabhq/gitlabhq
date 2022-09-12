# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::SubscriptionsController do
  describe 'GET /-/jira_connect/subscriptions' do
    let_it_be(:installation) { create(:jira_connect_installation, instance_url: 'http://self-managed-gitlab.com') }

    let(:qsh) do
      Atlassian::Jwt.create_query_string_hash('https://gitlab.test/subscriptions', 'GET', 'https://gitlab.test')
    end

    let(:jwt) { Atlassian::Jwt.encode({ iss: installation.client_key, qsh: qsh }, installation.shared_secret) }

    subject(:content_security_policy) do
      get '/-/jira_connect/subscriptions', params: { jwt: jwt }

      response.headers['Content-Security-Policy']
    end

    it { is_expected.to include('http://self-managed-gitlab.com/-/jira_connect/') }
    it { is_expected.to include('http://self-managed-gitlab.com/api/') }

    context 'with no self-managed instance configured' do
      let_it_be(:installation) { create(:jira_connect_installation, instance_url: '') }

      it { is_expected.not_to include('http://self-managed-gitlab.com/-/jira_connect/') }
      it { is_expected.not_to include('http://self-managed-gitlab.com/api/') }
    end

    context 'with jira_connect_oauth_self_managed feature disabled' do
      before do
        stub_feature_flags(jira_connect_oauth_self_managed: false)
      end

      it { is_expected.not_to include('http://self-managed-gitlab.com/-/jira_connect/') }
      it { is_expected.not_to include('http://self-managed-gitlab.com/api/') }
    end
  end
end
