# frozen_string_literal: true

require 'spec_helper'
require 'tty/prompt/test'
require_relative '../../../../../scripts/internal_events/cli'

RSpec.describe 'InternalEventsCli::Helpers::GroupOwnership', feature_category: :service_ping do
  include_context 'when running the Internal Events Cli'

  let(:flow) { Cli.new(prompt) }
  let(:all_categories) { Gitlab::FeatureCategories.default.categories.to_a }
  let(:package_categories) { %w[helm_chart_registry package_registry] }
  let(:container_categories) { %w[container_registry dependency_firewall virtual_registry] }

  describe '#category_choices' do
    subject(:choices) { flow.send(:category_choices, groups) }

    context 'with no group' do
      let(:groups) { nil }

      it 'gives a simple list of options' do
        is_expected.to eq [
          *all_categories,
          { name: "N/A (this definition does not correspond to any product categories)", value: nil }
        ]
      end
    end

    context 'with one group' do
      let(:groups) { %w[package_registry] }

      it 'lists the categories for that group first' do
        is_expected.to eq([
          { name: "-- Categories for package_registry --", value: nil, disabled: '' },
          *package_categories,
          { name: "-- All categories --", value: nil, disabled: '' },
          *(all_categories - package_categories),
          { name: "N/A (this definition does not correspond to any product categories)", value: nil }
        ])
      end
    end

    context 'with multiple groups' do
      let(:groups) { %w[package_registry container_registry] }

      it 'lists the categories for those groups first' do
        is_expected.to eq([
          { name: "-- Categories for package_registry --", value: nil, disabled: '' },
          *package_categories,
          { name: "-- Categories for container_registry --", value: nil, disabled: '' },
          *container_categories,
          { name: "-- All categories --", value: nil, disabled: '' },
          *(all_categories - package_categories - container_categories),
          { name: "N/A (this definition does not correspond to any product categories)", value: nil }
        ])
      end
    end

    context 'with groups that do not own categories' do
      let(:groups) { %w[package_registry foundations] }

      it 'does not show a separate section for those groups' do
        is_expected.to eq([
          { name: "-- Categories for package_registry --", value: nil, disabled: '' },
          *package_categories,
          { name: "-- All categories --", value: nil, disabled: '' },
          *(all_categories - package_categories),
          { name: "N/A (this definition does not correspond to any product categories)", value: nil }
        ])
      end
    end

    context 'when offline' do
      let(:groups) { %w[package_registry] }

      before do
        stub_product_groups(nil)
      end

      it 'gives a simple list of options' do
        is_expected.to eq [
          *all_categories,
          { name: "N/A (this definition does not correspond to any product categories)", value: nil }
        ]
      end
    end
  end
end
