# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::Jira::DevInfoClient, feature_category: :integrations do
  subject(:client) { described_class.new('https://gitlab-test.atlassian.net') }

  describe '#headers' do
    it 'must be implemented by a subclass' do
      expect { client.send(:headers, 'https://example.test') }
        .to raise_error(Gitlab::AbstractMethodError, /#{described_class} must implement #headers/)
    end
  end

  describe '#auth_error_message' do
    it 'does not name a credential the subclass may not use' do
      expect(client.send(:auth_error_message)).to eq('Authentication failed')
    end
  end
end
