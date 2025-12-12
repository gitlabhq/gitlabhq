# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Jira::Requests::Issues::ListService, feature_category: :integrations do
  describe 'abstract methods' do
    let(:service) { described_class.new(build(:jira_integration)) }

    it 'raises NotImplementedError for build_success_response' do
      expect { service.send(:build_success_response, {}) }.to raise_error(NotImplementedError)
    end
  end
end
