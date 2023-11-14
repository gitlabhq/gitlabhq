# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StubSaasFeatures, feature_category: :shared do
  describe '#stub_saas_features' do
    using RSpec::Parameterized::TableSyntax

    let(:feature_name) { :feature_one }
    let(:all_features) { [feature_name, :feature_two, :feature_three] }

    before do
      stub_const("Gitlab::Saas::FEATURES", all_features)
    end

    context 'when checking global state' do
      where(:feature_value) do
        [true, false]
      end

      with_them do
        before do
          stub_saas_features(feature_name => feature_value)
        end

        it { expect(::Gitlab::Saas.feature_available?(feature_name)).to eq(feature_value) }
      end
    end

    context 'when value is not boolean' do
      it 'raises an error' do
        expect do
          stub_saas_features(feature_name => '_not_boolean_')
        end.to raise_error(ArgumentError, /value must be boolean/)
      end
    end

    it 'subsequent run changes state' do
      # enable FF on all
      stub_saas_features({ feature_name => true })
      expect(::Gitlab::Saas.feature_available?(feature_name)).to eq(true)

      # disable FF on all
      stub_saas_features({ feature_name => false })
      expect(::Gitlab::Saas.feature_available?(feature_name)).to eq(false)
    end

    it 'handles multiple features' do
      stub_saas_features(feature_name => false, some_new_feature: true)

      expect(::Gitlab::Saas.feature_available?(feature_name)).to eq(false)
      expect(::Gitlab::Saas.feature_available?(:some_new_feature)).to eq(true)
    end

    context 'when checking multiple features' do
      it 'stubs defaults false value for other known features' do
        stub_saas_features(feature_one: true)

        expect(::Gitlab::Saas.feature_available?(:feature_one)).to eq(true)
        expect(::Gitlab::Saas.feature_available?(:feature_two)).to eq(false)
        expect(::Gitlab::Saas.feature_available?(:feature_three)).to eq(false)
      end
    end
  end
end
