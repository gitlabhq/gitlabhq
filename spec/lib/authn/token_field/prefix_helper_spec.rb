# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::TokenField::PrefixHelper, feature_category: :system_access do
  describe '.prepend_instance_prefix' do
    let(:prefix) { 'prefix' }

    subject(:prepend_instance_prefix) { described_class.prepend_instance_prefix(prefix) }

    context 'with application config default value' do
      it 'prepends the instance wide token prefix' do
        expect(prepend_instance_prefix).to eq("gl#{prefix}")
      end
    end

    context 'with application config set to custom value' do
      let(:instance_prefix) { 'instance-prefix-' }

      before do
        stub_application_setting(instance_token_prefix: instance_prefix)
      end

      it 'prepends the instance wide token prefix' do
        expect(prepend_instance_prefix).to eq("#{instance_prefix}#{prefix}")
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

  describe '.default_instance_prefix' do
    let(:prefix) { 'glprefix' }

    subject(:default_instance_prefix) { described_class.default_instance_prefix(prefix) }

    context 'with application config default value' do
      it 'returns the default prefix' do
        expect(default_instance_prefix).to eq(prefix)
      end
    end

    context 'with application config set to custom value' do
      let(:instance_prefix) { 'instance-prefix-' }

      before do
        stub_application_setting(instance_token_prefix: instance_prefix)
      end

      context 'for the default prefix' do
        it 'still returns the default prefix' do
          expect(default_instance_prefix).to eq(prefix)
        end
      end

      context 'for the current instance prefix' do
        let(:prefix) { "#{instance_prefix}token-prefix" }

        it 'changes the instance prefix to the default prefix' do
          expect(default_instance_prefix).to eq('gltoken-prefix')
        end
      end

      context 'for a non-matching prefix' do
        let(:prefix) { 'different-token-prefix' }

        it 'keeps the prefix unchanged' do
          expect(default_instance_prefix).to eq(prefix)
        end
      end
    end

    context 'with feature flag custom_prefix_for_all_token_types disabled' do
      before do
        stub_feature_flags(custom_prefix_for_all_token_types: false)
      end

      it 'keeps the prefix unchanged' do
        expect(default_instance_prefix).to eq(prefix)
      end
    end
  end
end
