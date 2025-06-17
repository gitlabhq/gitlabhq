# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Security::DastVariables, feature_category: :dynamic_application_security_testing do
  let(:dast_variables) { described_class }

  describe '#additional_site_variables' do
    [:site, :scanner].each do |type|
      it "contains additional #{type} variables" do
        described_class.data[type].each do |key, variable|
          if variable[:additional]
            expect(described_class.additional_site_variables[key]).not_to be_nil
          else
            expect(described_class.additional_site_variables[key]).to be_nil
          end
        end
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
