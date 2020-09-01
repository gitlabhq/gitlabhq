# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Jira::Middleware do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }
  let(:jira_user_agent) { 'Jira DVCS Connector Vertigo/5.0.0-D20170810T012915' }

  describe '.jira_dvcs_connector?' do
    it 'returns true when DVCS connector' do
      expect(described_class.jira_dvcs_connector?('HTTP_USER_AGENT' => jira_user_agent)).to eq(true)
    end

    it 'returns true if user agent starts with "Jira DVCS Connector"' do
      expect(described_class.jira_dvcs_connector?('HTTP_USER_AGENT' => 'Jira DVCS Connector')).to eq(true)
    end

    it 'returns false when not DVCS connector' do
      expect(described_class.jira_dvcs_connector?('HTTP_USER_AGENT' => 'pokemon')).to eq(false)
    end
  end

  describe '#call' do
    it 'adjusts HTTP_AUTHORIZATION env when request from Jira DVCS user agent' do
      expect(app).to receive(:call).with('HTTP_USER_AGENT' => jira_user_agent,
                                         'HTTP_AUTHORIZATION' => 'Bearer hash-123')

      middleware.call('HTTP_USER_AGENT' => jira_user_agent, 'HTTP_AUTHORIZATION' => 'token hash-123')
    end

    it 'does not change HTTP_AUTHORIZATION env when request is not from Jira DVCS user agent' do
      env = { 'HTTP_USER_AGENT' => 'Mozilla/5.0', 'HTTP_AUTHORIZATION' => 'token hash-123' }

      expect(app).to receive(:call).with(env)

      middleware.call(env)
    end
  end
end
