# frozen_string_literal: true

require 'spec_helper'

describe StubFeatureFlags do
  before do
    # reset stub introduced by `stub_feature_flags`
    allow(Feature).to receive(:enabled?).and_call_original
  end

  context 'if not stubbed' do
    it 'features are disabled by default' do
      expect(Feature.enabled?(:test_feature)).to eq(false)
    end
  end

  describe '#stub_feature_flags' do
    using RSpec::Parameterized::TableSyntax

    let(:feature_name) { :test_feature }

    context 'when checking global state' do
      where(:feature_actors, :expected_result) do
        false   | false
        true    | true
        :A      | false
        %i[A]   | false
        %i[A B] | false
      end

      with_them do
        before do
          stub_feature_flags(feature_name => feature_actors)
        end

        it { expect(Feature.enabled?(feature_name)).to eq(expected_result) }
        it { expect(Feature.disabled?(feature_name)).not_to eq(expected_result) }

        context 'default_enabled does not impact feature state' do
          it { expect(Feature.enabled?(feature_name, default_enabled: true)).to eq(expected_result) }
          it { expect(Feature.disabled?(feature_name, default_enabled: true)).not_to eq(expected_result) }
        end
      end
    end

    context 'when checking scoped state' do
      where(:feature_actors, :tested_actor, :expected_result) do
        false   | nil  | false
        true    | nil  | true
        false   | :A   | false
        true    | :A   | true
        :A      | nil  | false
        :A      | :A   | true
        :A      | :B   | false
        %i[A]   | nil  | false
        %i[A]   | :A   | true
        %i[A]   | :B   | false
        %i[A B] | nil  | false
        %i[A B] | :A   | true
        %i[A B] | :B   | true
      end

      with_them do
        before do
          stub_feature_flags(feature_name => feature_actors)
        end

        it { expect(Feature.enabled?(feature_name, tested_actor)).to eq(expected_result) }
        it { expect(Feature.disabled?(feature_name, tested_actor)).not_to eq(expected_result) }

        context 'default_enabled does not impact feature state' do
          it { expect(Feature.enabled?(feature_name, tested_actor, default_enabled: true)).to eq(expected_result) }
          it { expect(Feature.disabled?(feature_name, tested_actor, default_enabled: true)).not_to eq(expected_result) }
        end
      end
    end

    context 'type handling' do
      context 'raises error' do
        where(:feature_actors) do
          ['string', 1, 1.0, OpenStruct.new]
        end

        with_them do
          subject { stub_feature_flags(feature_name => feature_actors) }

          it { expect { subject }.to raise_error(ArgumentError, /accepts only/) }
        end
      end

      context 'does not raise error' do
        where(:feature_actors) do
          [true, false, nil, :symbol, double, User.new]
        end

        with_them do
          subject { stub_feature_flags(feature_name => feature_actors) }

          it { expect { subject }.not_to raise_error }
        end
      end
    end

    it 'subsquent run changes state' do
      # enable FF only on A
      stub_feature_flags(test_feature: %i[A])
      expect(Feature.enabled?(:test_feature)).to eq(false)
      expect(Feature.enabled?(:test_feature, :A)).to eq(true)
      expect(Feature.enabled?(:test_feature, :B)).to eq(false)

      # enable FF only on B
      stub_feature_flags(test_feature: %i[B])
      expect(Feature.enabled?(:test_feature)).to eq(false)
      expect(Feature.enabled?(:test_feature, :A)).to eq(false)
      expect(Feature.enabled?(:test_feature, :B)).to eq(true)

      # enable FF on all
      stub_feature_flags(test_feature: true)
      expect(Feature.enabled?(:test_feature)).to eq(true)
      expect(Feature.enabled?(:test_feature, :A)).to eq(true)
      expect(Feature.enabled?(:test_feature, :B)).to eq(true)

      # disable FF on all
      stub_feature_flags(test_feature: false)
      expect(Feature.enabled?(:test_feature)).to eq(false)
      expect(Feature.enabled?(:test_feature, :A)).to eq(false)
      expect(Feature.enabled?(:test_feature, :B)).to eq(false)
    end
  end
end
