# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Limitable do
  let(:minimal_test_class) do
    Class.new do
      include ActiveModel::Model

      def self.name
        'TestClass'
      end

      include Limitable
    end
  end

  before do
    stub_const('MinimalTestClass', minimal_test_class)
  end

  it { expect(MinimalTestClass.limit_name).to eq('test_classes') }

  context 'with scoped limit' do
    before do
      MinimalTestClass.limit_scope = :project
    end

    it { expect(MinimalTestClass.limit_scope).to eq(:project) }

    it 'triggers scoped validations' do
      instance = MinimalTestClass.new

      expect(instance).to receive(:scoped_plan_limits)

      instance.valid?(:create)
    end

    context 'with custom relation and feature flags' do
      using RSpec::Parameterized::TableSyntax

      where(:limit_feature_flag, :limit_feature_flag_value, :limit_feature_flag_for_override, :limit_feature_flag_override_value, :expect_limit_applied?) do
        nil                | nil   | nil                        | nil   | true
        :some_feature_flag | false | nil                        | nil   | false
        :some_feature_flag | true  | nil                        | nil   | true
        :some_feature_flag | true  | :some_feature_flag_disable | false | true
        :some_feature_flag | false | :some_feature_flag_disable | false | false
        :some_feature_flag | false | :some_feature_flag_disable | true  | false
        :some_feature_flag | true  | :some_feature_flag_disable | true  | false
      end

      with_them do
        let(:instance) { MinimalTestClass.new }

        before do
          def instance.project
            @project ||= stub_feature_flag_gate('CustomActor')
          end

          stub_feature_flags("#{limit_feature_flag}": limit_feature_flag_value ? [instance.project] : false) if limit_feature_flag
          stub_feature_flags("#{limit_feature_flag_for_override}": limit_feature_flag_override_value ? [instance.project] : false) if limit_feature_flag_for_override
          skip_default_enabled_yaml_check

          MinimalTestClass.limit_relation = :custom_relation
          MinimalTestClass.limit_feature_flag = limit_feature_flag
          MinimalTestClass.limit_feature_flag_for_override = limit_feature_flag_for_override
        end

        it 'acts according to the feature flag settings' do
          limits = Object.new
          custom_relation = Object.new
          if expect_limit_applied?
            expect(instance).to receive(:custom_relation).and_return(custom_relation)
            expect(instance.project).to receive(:actual_limits).and_return(limits)
            expect(limits).to receive(:exceeded?).with(instance.class.name.demodulize.tableize, custom_relation).and_return(false)
          else
            expect(instance).not_to receive(:custom_relation)
          end

          instance.valid?(:create)
        end
      end
    end
  end

  context 'with global limit' do
    before do
      MinimalTestClass.limit_scope = Limitable::GLOBAL_SCOPE
    end

    it { expect(MinimalTestClass.limit_scope).to eq(Limitable::GLOBAL_SCOPE) }

    it 'triggers scoped validations' do
      instance = MinimalTestClass.new

      expect(instance).to receive(:global_plan_limits)

      instance.valid?(:create)
    end
  end
end
