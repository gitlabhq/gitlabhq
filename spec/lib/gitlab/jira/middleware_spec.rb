require 'spec_helper'

describe Gitlab::Jira::Middleware do
  let(:app) { double(:app) }
  let(:middleware) { described_class.new(app) }

  describe '#call' do
    it 'adjusts HTTP_AUTHORIZATION env when request from JIRA DVCS user agent' do
      user_agent = 'JIRA DVCS Connector Vertigo/5.0.0-D20170810T012915'

      expect(app).to receive(:call).with('HTTP_USER_AGENT' => user_agent,
                                         'HTTP_AUTHORIZATION' => 'Bearer hash-123')

      middleware.call('HTTP_USER_AGENT' => user_agent, 'HTTP_AUTHORIZATION' => 'token hash-123')
    end

    it 'does not change HTTP_AUTHORIZATION env when request is not from JIRA DVCS user agent' do
      env = { 'HTTP_USER_AGENT' => 'Mozilla/5.0', 'HTTP_AUTHORIZATION' => 'token hash-123' }

      expect(app).to receive(:call).with(env)

      middleware.call(env)
    end
  end
end
