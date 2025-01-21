# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::CollectPipelineAnalyticsServiceBase, feature_category: :fleet_visibility do
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:current_user) { build_stubbed(:user, reporter_of: project) }

  let(:test_class) { stub_const('TestService', Class.new(described_class)) }
  let(:service) { test_class.new(current_user: current_user, project: project, from_time: nil, to_time: nil) }

  subject(:result) { service.execute }

  describe '.fetch_response' do
    it 'raises a NotImplementedError for the base service' do
      expect do
        service.send(:fetch_response)
      end.to raise_error(NotImplementedError, "#{test_class.name} must implement `fetch_response`")
    end
  end
end
