# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Feature, :request_store, :clean_gitlab_redis_feature_flag,
  stub_feature_flags: false, feature_category: :feature_flags do
  let(:feature_flag_name) { :test_observed_flag }
  let(:observed) { true }
  let(:definition_options) { { observed: observed, type: 'ops' } }

  before do
    stub_feature_flag_definition(feature_flag_name, **definition_options)
    described_class.reset
  end

  after do
    # Reload definitions to clear stubbed feature flags for subsequent tests
    Feature::Definition.reload!
  end

  describe '.enabled? with observed flags' do
    let(:observed_flags) { Gitlab::ApplicationContext.current_context_attribute(:feature_flags) }
    let_it_be(:actor) { create(:user) }

    context 'when feature flag is enabled' do
      before do
        described_class.enable(feature_flag_name, actor)
      end

      context 'and observed' do
        it 'adds the flag to ApplicationContext' do
          described_class.enabled?(feature_flag_name, actor)

          expect(observed_flags).to eq([feature_flag_name.to_s])
        end

        it 'does not add duplicate flags' do
          described_class.enabled?(feature_flag_name, actor)
          described_class.enabled?(feature_flag_name, actor)

          expect(observed_flags).to eq([feature_flag_name.to_s])
        end

        it 'adds multiple different flags' do
          stub_feature_flag_definition(:flag1, observed: true, type: 'ops')
          stub_feature_flag_definition(:flag2, observed: true, type: 'ops')
          described_class.enable(:flag1, actor)
          described_class.enable(:flag2, actor)

          described_class.enabled?(:flag1, actor)
          described_class.enabled?(:flag2, actor)

          expect(observed_flags).to contain_exactly('flag1', 'flag2')
        end

        it 'stops adding flags after MAX_OBSERVED_FEATURE_FLAGS limit' do
          (Feature::MAX_OBSERVED_FEATURE_FLAGS + 1).times do |i|
            flag_name = :"flag_#{i}"
            stub_feature_flag_definition(flag_name, observed: true, type: 'ops')
            described_class.enable(flag_name, actor)
            described_class.enabled?(flag_name, actor)
          end

          expect(observed_flags.size).to eq(Feature::MAX_OBSERVED_FEATURE_FLAGS)
          expect(observed_flags.size).to eq(10)
        end
      end

      context 'and not observed' do
        let(:observed) { false }

        it 'does not add the flag to ApplicationContext' do
          described_class.enabled?(feature_flag_name, actor)

          expect(observed_flags).to be_nil
        end
      end
    end

    context 'when feature flag is disabled and observed' do
      before do
        described_class.disable(feature_flag_name)
      end

      it 'does not add the flag to ApplicationContext' do
        described_class.enabled?(feature_flag_name, actor)

        expect(observed_flags).to be_nil
      end

      it 'returns false' do
        expect(described_class.enabled?(feature_flag_name, actor)).to be(false)
      end
    end

    context 'when feature flag definition does not have observed attribute' do
      let(:definition_options) { { type: 'ops' } }

      before do
        described_class.enable(feature_flag_name, actor)
      end

      it 'does not add the flag to ApplicationContext' do
        described_class.enabled?(feature_flag_name, actor)

        expect(observed_flags).to be_nil
      end
    end
  end

  describe 'MAX_OBSERVED_FEATURE_FLAGS constant' do
    it 'is defined and set to 10' do
      expect(Feature::MAX_OBSERVED_FEATURE_FLAGS).to eq(10)
    end
  end
end
