# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::FeatureFlags, feature_category: :pipeline_composition do
  let(:feature_flag) { :my_feature_flag }

  context 'when the actor is set' do
    let(:actor) { double }
    let(:another_actor) { double }

    it 'checks the feature flag using the given actor' do
      described_class.with_actor(actor) do
        expect(Feature).to receive(:enabled?).with(feature_flag, actor)

        described_class.enabled?(feature_flag)
      end
    end

    it 'returns the value of the block' do
      result = described_class.with_actor(actor) do
        :test
      end

      expect(result).to eq(:test)
    end

    it 'restores the existing actor if any' do
      described_class.with_actor(actor) do
        described_class.with_actor(another_actor) do
          expect(Feature).to receive(:enabled?).with(feature_flag, another_actor)

          described_class.enabled?(feature_flag)
        end

        expect(Feature).to receive(:enabled?).with(feature_flag, actor)
        described_class.enabled?(feature_flag)
      end
    end

    it 'restores the actor to nil after the block' do
      described_class.with_actor(actor) do
        expect(Thread.current[described_class::ACTOR_KEY]).to eq(actor)
      end

      expect(Thread.current[described_class::ACTOR_KEY]).to be nil
    end
  end

  context 'when feature flag is checked outside the "with_actor" block' do
    context 'when ci_config_feature_flag_correctness is used' do
      it 'raises an error on dev/test environment' do
        expect { described_class.enabled?(feature_flag) }.to raise_error(described_class::NoActorError)
      end

      context 'when on production' do
        before do
          allow(Gitlab::ErrorTracking).to receive(:should_raise_for_dev?).and_return(false)
        end

        it 'checks the feature flag without actor' do
          expect(Feature).to receive(:enabled?).with(feature_flag, nil)
          expect(Gitlab::ErrorTracking)
            .to receive(:track_and_raise_for_dev_exception)
            .and_call_original

          described_class.enabled?(feature_flag)
        end
      end
    end
  end

  context 'when actor is explicitly nil' do
    it 'checks the feature flag without actor' do
      described_class.with_actor(nil) do
        expect(Feature).to receive(:enabled?).with(feature_flag, nil)

        described_class.enabled?(feature_flag)
      end
    end
  end
end
