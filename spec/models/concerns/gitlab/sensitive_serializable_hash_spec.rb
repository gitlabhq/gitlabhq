# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SensitiveSerializableHash, feature_category: :shared do
  describe '.prevent_from_serialization' do
    let(:base_class) do
      Class.new do
        include ActiveModel::Serialization
        include Gitlab::SensitiveSerializableHash
      end
    end

    let(:test_class) do
      Class.new(base_class) do
        attr_accessor :name, :super_secret

        prevent_from_serialization :super_secret

        def attributes
          { 'name' => nil, 'super_secret' => nil }
        end
      end
    end

    let(:another_class) do
      Class.new(base_class) do
        prevent_from_serialization :sub_secret
      end
    end

    let(:model) { test_class.new }

    it 'does not include the field in serializable_hash' do
      expect(model.serializable_hash).not_to include('super_secret')
    end

    it 'does not change parent class attributes_exempt_from_serializable_hash' do
      expect(test_class.attributes_exempt_from_serializable_hash).to contain_exactly(:super_secret)
      expect(another_class.attributes_exempt_from_serializable_hash).to contain_exactly(:sub_secret)
    end
  end

  describe '#serializable_hash' do
    shared_examples "attr_encrypted attribute" do |klass, attribute_name|
      context "for #{klass.name}\##{attribute_name}" do
        let(:attributes) { [attribute_name, "encrypted_#{attribute_name}", "encrypted_#{attribute_name}_iv"] }

        it 'has a attr_encrypted_attributes field' do
          expect(klass.attr_encrypted_attributes).to include(attribute_name.to_sym)
        end

        it 'does not include the attribute in serializable_hash', :aggregate_failures do
          attributes.each do |attribute|
            expect(model.attributes).to include(attribute) # double-check the attribute does exist

            expect(model.serializable_hash).not_to include(attribute)
            expect(model.to_json).not_to include(attribute.to_json)
            expect(model.as_json).not_to include(attribute)
          end
        end
      end
    end

    context 'for a web hook' do
      let_it_be(:model) { create(:system_hook) }

      it_behaves_like 'attr_encrypted attribute', WebHook, 'token'
      it_behaves_like 'attr_encrypted attribute', WebHook, 'url'
      it_behaves_like 'attr_encrypted attribute', WebHook, 'url_variables'
    end

    it_behaves_like 'attr_encrypted attribute', Ci::InstanceVariable, 'value' do
      let_it_be(:model) { create(:ci_instance_variable) }
    end

    shared_examples "add_authentication_token_field attribute" do |klass, attribute_name|
      context "for #{klass.name}\##{attribute_name}" do
        it 'has a add_authentication_token_field field' do
          expect(klass.token_authenticatable_fields).to include(attribute_name.to_sym)
        end

        it 'does not include the attribute in serializable_hash', :aggregate_failures do
          attributes.each do |attribute|
            expect(model.attributes).to include(attribute) # double-check the attribute does exist

            expect(model.serializable_hash).not_to include(attribute)
            expect(model.to_json).not_to match(/\b#{attribute}\b/)
            expect(model.as_json).not_to include(attribute)
          end
        end
      end
    end

    it_behaves_like 'add_authentication_token_field attribute', Ci::Runner, 'token' do
      let_it_be(:model) { create(:ci_runner) }

      let(:attributes) { %w[token token_encrypted] }
    end

    it_behaves_like 'add_authentication_token_field attribute', ApplicationSetting, 'health_check_access_token' do
      let_it_be(:model) { create(:application_setting) }

      # health_check_access_token_encrypted column does not exist
      let(:attributes) { %w[health_check_access_token] }
    end

    it_behaves_like 'add_authentication_token_field attribute', PersonalAccessToken, 'token' do
      let_it_be(:model) { create(:personal_access_token) }

      # PersonalAccessToken only has token_digest column
      let(:attributes) { %w[token_digest] }
    end
  end
end
