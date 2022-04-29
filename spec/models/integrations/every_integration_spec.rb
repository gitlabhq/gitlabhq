# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Every integration' do
  all_integration_names = Integration.available_integration_names

  all_integration_names.each do |integration_name|
    describe integration_name do
      let(:integration_class) { Integration.integration_name_to_model(integration_name) }
      let(:integration) { integration_class.new }
      let(:secret_name_pattern) { %r/token|key|password|passphrase|secret/.freeze }

      context 'secret fields', :aggregate_failures do
        it "uses type: 'password' for all secret fields" do
          integration.fields.each do |field|
            next unless secret_name_pattern.match?(field[:name])

            expect(field[:type]).to eq('password'),
              "Field '#{field[:name]}' should use type 'password'"
          end
        end

        it 'defines non-empty titles and help texts for all secret fields' do
          integration.fields.each do |field|
            next unless field[:type] == 'password'

            expect(field[:non_empty_password_title]).to be_present,
              "Field '#{field[:name]}' should define :non_empty_password_title"
            expect(field[:non_empty_password_help]).to be_present,
              "Field '#{field[:name]}' should define :non_empty_password_help"
          end
        end
      end
    end
  end
end
