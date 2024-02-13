# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServicePing::BuildPayload, feature_category: :service_ping do
  describe '#execute', :without_license,
    quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/438582' do
    subject(:service_ping_payload) { described_class.new.execute }

    include_context 'stubbed service ping metrics definitions'

    it_behaves_like 'complete service ping payload'
  end
end
