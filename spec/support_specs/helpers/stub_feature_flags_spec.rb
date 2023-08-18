# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StubFeatureFlags do
  let_it_be(:dummy_feature_flag) { :dummy_feature_flag }

  let_it_be(:dummy_definition) do
    Feature::Definition.new(
      nil,
      name: dummy_feature_flag,
      type: 'development',
      default_enabled: false
    )
  end

  # We inject dummy feature flag defintion
  # to ensure that we strong validate it's usage
  # as well
  before_all do
    Feature::Definition.definitions[dummy_feature_flag] = dummy_definition
  end

  after(:all) do
    Feature::Definition.definitions.delete(dummy_feature_flag)
  end

  describe '#stub_feature_flags' do
    using RSpec::Parameterized::TableSyntax

    let(:feature_name) { dummy_feature_flag }

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

        context 'default_enabled_if_undefined does not impact feature state' do
          before do
            allow(dummy_definition).to receive(:default_enabled).and_return(true)
          end

          it { expect(Feature.enabled?(feature_name, default_enabled_if_undefined: true)).to eq(expected_result) }
          it { expect(Feature.disabled?(feature_name, default_enabled_if_undefined: true)).not_to eq(expected_result) }
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

        context 'default_enabled_if_undefined does not impact feature state' do
          before do
            allow(dummy_definition).to receive(:default_enabled).and_return(true)
          end

          it { expect(Feature.enabled?(feature_name, actor(tested_actor), default_enabled_if_undefined: true)).to eq(expected_result) }
          it { expect(Feature.disabled?(feature_name, actor(tested_actor), default_enabled_if_undefined: true)).not_to eq(expected_result) }
        end
      end
    end

    context 'type handling' do
      context 'raises error' do
        where(:feature_actors) do
          ['string', 1, 1.0, Object.new]
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

  describe 'stub timing' do
    context 'let_it_be variable' do
      let_it_be(:let_it_be_var) { Feature.enabled?(dummy_feature_flag) }

      it { expect(let_it_be_var).to eq true }
    end

    # rubocop: disable RSpec/BeforeAll
    context 'before_all variable' do
      before_all do
        @suite_var = Feature.enabled?(dummy_feature_flag)
      end

      it { expect(@suite_var).to eq true }
    end

    context 'before(:all) variable' do
      before(:all) do
        @suite_var = Feature.enabled?(dummy_feature_flag)
      end

      it { expect(@suite_var).to eq true }
    end
    # rubocop: enable RSpec/BeforeAll

    context 'with stub_feature_flags meta' do
      let(:var) { Feature.enabled?(dummy_feature_flag) }

      context 'as true', :stub_feature_flags do
        it { expect(var).to eq true }
      end

      context 'as false', stub_feature_flags: false do
        it { expect(var).to eq false }
      end
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
