# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::TokenField::PrefixHelper, feature_category: :system_access do
  describe '.prepend_instance_prefix' do
    let(:prefix) { 'prefix' }

    subject(:prepend_instance_prefix) { described_class.prepend_instance_prefix(prefix) }

    context 'with application config default value' do
      it 'returns the prefix without prepending the instance prefix' do
        expect(prepend_instance_prefix).to eq(prefix)
      end
    end

    context 'with application config set to custom value' do
      let(:instance_prefix) { 'instanceprefix' }

      before do
        stub_application_setting(instance_token_prefix: instance_prefix)
      end

      it 'prepends the instance wide token prefix' do
        expect(prepend_instance_prefix).to eq("#{instance_prefix}-#{prefix}")
      end
    end

    context 'with the legacy default value "gl"' do
      before do
        stub_application_setting(instance_token_prefix: 'gl')
      end

      it 'treats the leftover default as unset and does not prepend it' do
        expect(prepend_instance_prefix).to eq(prefix)
      end
    end

    context 'with feature flag custom_prefix_for_all_token_types disabled' do
      before do
        stub_feature_flags(custom_prefix_for_all_token_types: false)
      end

      it 'does not prepend the instance wide token prefix' do
        expect(prepend_instance_prefix).to eq(prefix)
      end
    end
  end

  describe '.instance_prefix' do
    subject(:instance_prefix) { described_class.instance_prefix }

    context 'with application config default value' do
      it 'returns an empty string' do
        expect(instance_prefix).to eq('')
      end
    end

    context 'with application config set to a custom value' do
      before do
        stub_application_setting(instance_token_prefix: 'acme')
      end

      it 'returns the configured prefix' do
        expect(instance_prefix).to eq('acme')
      end
    end

    context 'with the legacy default value "gl"' do
      before do
        stub_application_setting(instance_token_prefix: 'gl')
      end

      it 'returns an empty string' do
        expect(instance_prefix).to eq('')
      end
    end

    context 'with feature flag custom_prefix_for_all_token_types disabled' do
      before do
        stub_feature_flags(custom_prefix_for_all_token_types: false)
        stub_application_setting(instance_token_prefix: 'acme')
      end

      it 'returns an empty string' do
        expect(instance_prefix).to eq('')
      end
    end
  end
end
