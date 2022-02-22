# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Atlassian::JiraConnect do
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
  end
end
