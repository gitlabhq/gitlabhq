# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::JiraConnect, feature_category: :integrations do
  describe '.app_name' do
    subject { described_class.app_name }

    it { is_expected.to eq('GitLab for Jira (localhost)') }
  end

  describe '.app_key' do
    subject(:app_key) { described_class.app_key }

    it { is_expected.to eq('gitlab-jira-connect-localhost') }

    context 'host name is too long' do
      before do
        hostname = 'x' * 100

        stub_config(gitlab: { host: hostname })
      end

      it 'truncates the key to be no longer than 64 characters', :aggregate_failures do
        expect(app_key).to eq('gitlab-jira-connect-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx')
      end
    end

    context 'with jira_connect_proxy_url setting' do
      before do
        stub_application_setting(jira_connect_proxy_url: 'https://example.com')
      end

      it { is_expected.to eq('gitlab-jira-connect-example.com') }
    end
  end

  describe '.gov_cloud?' do
    using RSpec::Parameterized::TableSyntax

    where(:url, :result) do
      'https://example.atlassian-us-gov-mod.net'    | true
      'https://EXAMPLE.atlassian-us-gov-mod.net'    | true
      'https://example.atlassian-us-gov-mod.com'    | true
      'https://example.atlassian.net'               | false
      'https://atlassian-us-gov-mod.net.example.com' | false
      'https://example.com/atlassian-us-gov-mod.net' | false
      'https://evilatlassian-us-gov-mod.net'        | false
      'not a url'                                   | false
      ''                                            | false
      nil                                           | false
    end

    with_them do
      it { expect(described_class.gov_cloud?(url)).to be(result) }
    end
  end
end
