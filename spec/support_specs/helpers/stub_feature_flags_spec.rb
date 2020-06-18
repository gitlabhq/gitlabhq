# frozen_string_literal: true

require 'spec_helper'

describe StubFeatureFlags do
  let(:feature_name) { :test_feature }

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
          stub_feature_flags(feature_name => actor(feature_actors))
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
          stub_feature_flags(feature_name => actor(feature_actors))
        end

        it { expect(Feature.enabled?(feature_name, actor(tested_actor))).to eq(expected_result) }
        it { expect(Feature.disabled?(feature_name, actor(tested_actor))).not_to eq(expected_result) }

        context 'default_enabled does not impact feature state' do
          it { expect(Feature.enabled?(feature_name, actor(tested_actor), default_enabled: true)).to eq(expected_result) }
          it { expect(Feature.disabled?(feature_name, actor(tested_actor), default_enabled: true)).not_to eq(expected_result) }
        end
      end
    end

    context 'type handling' do
      context 'raises error' do
        where(:feature_actors) do
          ['string', 1, 1.0, OpenStruct.new]
        end

        with_them do
          subject { stub_feature_flags(feature_name => actor(feature_actors)) }

          it { expect { subject }.to raise_error(ArgumentError, /accepts only/) }
        end
      end

      context 'does not raise error' do
        where(:feature_actors) do
          [true, false, nil, stub_feature_flag_gate(100), User.new]
        end

        with_them do
          subject { stub_feature_flags(feature_name => actor(feature_actors)) }

          it { expect { subject }.not_to raise_error }
        end
      end
    end

    it 'subsquent run changes state' do
      # enable FF only on A
      stub_feature_flags({ feature_name => actor(%i[A]) })
      expect(Feature.enabled?(feature_name)).to eq(false)
      expect(Feature.enabled?(feature_name, actor(:A))).to eq(true)
      expect(Feature.enabled?(feature_name, actor(:B))).to eq(false)

      # enable FF only on B
      stub_feature_flags({ feature_name => actor(%i[B]) })
      expect(Feature.enabled?(feature_name)).to eq(false)
      expect(Feature.enabled?(feature_name, actor(:A))).to eq(false)
      expect(Feature.enabled?(feature_name, actor(:B))).to eq(true)

      # enable FF on all
      stub_feature_flags({ feature_name => true })
      expect(Feature.enabled?(feature_name)).to eq(true)
      expect(Feature.enabled?(feature_name, actor(:A))).to eq(true)
      expect(Feature.enabled?(feature_name, actor(:B))).to eq(true)

      # disable FF on all
      stub_feature_flags({ feature_name => false })
      expect(Feature.enabled?(feature_name)).to eq(false)
      expect(Feature.enabled?(feature_name, actor(:A))).to eq(false)
      expect(Feature.enabled?(feature_name, actor(:B))).to eq(false)
    end
  end

  def actor(actor)
    case actor
    when Array
      actor.map(&method(:actor))
    when Symbol # convert to flipper compatible object
      stub_feature_flag_gate(actor)
    else
      actor
    end
  end
end
