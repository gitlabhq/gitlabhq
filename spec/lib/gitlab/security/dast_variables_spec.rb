# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Security::DastVariables, feature_category: :dynamic_application_security_testing do
  let(:dast_variables) { described_class }

  describe '#additional_site_variables' do
    it 'contains only additional variables' do
      described_class.additional_site_variables.each_value do |variable|
        expect(variable[:additional]).to be(true)
      end
    end
  end

  describe '#auth_variables' do
    it 'contains only authentication variables' do
      described_class.auth_variables.each_value do |variable|
        expect(variable[:auth]).to be(true)
      end
    end
  end
end
