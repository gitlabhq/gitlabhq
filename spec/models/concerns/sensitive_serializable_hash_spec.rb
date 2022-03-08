# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SensitiveSerializableHash do
  describe '.prevent_from_serialization' do
    let(:test_class) do
      Class.new do
        include ActiveModel::Serialization
        include SensitiveSerializableHash

        attr_accessor :name, :super_secret

        prevent_from_serialization :super_secret

        def attributes
          { 'name' => nil, 'super_secret' => nil }
        end
      end
    end

    let(:model) { test_class.new }

    it 'does not include the field in serializable_hash' do
      expect(model.serializable_hash).not_to include('super_secret')
    end

    context 'unsafe_serialization_hash option' do
      it 'includes the field in serializable_hash' do
        expect(model.serializable_hash(unsafe_serialization_hash: true)).to include('super_secret')
      end
    end

    context 'when prevent_sensitive_fields_from_serializable_hash feature flag is disabled' do
      before do
        stub_feature_flags(prevent_sensitive_fields_from_serializable_hash: false)
      end

      it 'includes the field in serializable_hash' do
        expect(model.serializable_hash).to include('super_secret')
      end
    end
  end

  describe '#serializable_hash' do
    shared_examples "attr_encrypted attribute" do |klass, attribute_name|
      context "#{klass.name}\##{attribute_name}" do
        let(:attributes) { [attribute_name, "encrypted_#{attribute_name}", "encrypted_#{attribute_name}_iv"] }

        it 'has a encrypted_attributes field' do
          expect(klass.encrypted_attributes).to include(attribute_name.to_sym)
        end

        it 'does not include the attribute in serializable_hash', :aggregate_failures do
          attributes.each do |attribute|
            expect(model.attributes).to include(attribute) # double-check the attribute does exist

            expect(model.serializable_hash).not_to include(attribute)
            expect(model.to_json).not_to include(attribute)
            expect(model.as_json).not_to include(attribute)
          end
        end

        context 'unsafe_serialization_hash option' do
          it 'includes the field in serializable_hash' do
            attributes.each do |attribute|
              expect(model.attributes).to include(attribute) # double-check the attribute does exist

              expect(model.serializable_hash(unsafe_serialization_hash: true)).to include(attribute)
              expect(model.to_json(unsafe_serialization_hash: true)).to include(attribute)
              expect(model.as_json(unsafe_serialization_hash: true)).to include(attribute)
            end
          end
        end
      end
    end

    it_behaves_like 'attr_encrypted attribute', WebHook, 'token' do
      let_it_be(:model) { create(:system_hook) }
    end

    it_behaves_like 'attr_encrypted attribute', Ci::InstanceVariable, 'value' do
      let_it_be(:model) { create(:ci_instance_variable) }
    end

    shared_examples "add_authentication_token_field attribute" do |klass, attribute_name, encrypted_attribute: true, digest_attribute: false|
      context "#{klass.name}\##{attribute_name}" do
        let(:attributes) do
          if digest_attribute
            ["#{attribute_name}_digest"]
          elsif encrypted_attribute
            [attribute_name, "#{attribute_name}_encrypted"]
          else
            [attribute_name]
          end
        end

        it 'has a add_authentication_token_field field' do
          expect(klass.token_authenticatable_fields).to include(attribute_name.to_sym)
        end

        it 'does not include the attribute in serializable_hash', :aggregate_failures do
          attributes.each do |attribute|
            expect(model.attributes).to include(attribute) # double-check the attribute does exist

            expect(model.serializable_hash).not_to include(attribute)
            expect(model.to_json).not_to include(attribute)
            expect(model.as_json).not_to include(attribute)
          end
        end

        context 'unsafe_serialization_hash option' do
          it 'includes the field in serializable_hash' do
            attributes.each do |attribute|
              expect(model.attributes).to include(attribute) # double-check the attribute does exist

              expect(model.serializable_hash(unsafe_serialization_hash: true)).to include(attribute)
              expect(model.to_json(unsafe_serialization_hash: true)).to include(attribute)
              expect(model.as_json(unsafe_serialization_hash: true)).to include(attribute)
            end
          end
        end
      end
    end

    it_behaves_like 'add_authentication_token_field attribute', Ci::Runner, 'token' do
      let_it_be(:model) { create(:ci_runner) }

      it 'does not include token_expires_at in serializable_hash' do
        attribute = 'token_expires_at'

        expect(model.attributes).to include(attribute) # double-check the attribute does exist

        expect(model.serializable_hash).not_to include(attribute)
        expect(model.to_json).not_to include(attribute)
        expect(model.as_json).not_to include(attribute)
      end
    end

    it_behaves_like 'add_authentication_token_field attribute', ApplicationSetting, 'health_check_access_token', encrypted_attribute: false do
      # health_check_access_token_encrypted column does not exist
      let_it_be(:model) { create(:application_setting) }
    end

    it_behaves_like 'add_authentication_token_field attribute', PersonalAccessToken, 'token', encrypted_attribute: false, digest_attribute: true do
      # PersonalAccessToken only has token_digest column
      let_it_be(:model) { create(:personal_access_token) }
    end
  end
end
