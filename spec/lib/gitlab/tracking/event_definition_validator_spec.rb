# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Tracking::EventDefinitionValidator, feature_category: :service_ping do
  let(:attributes) do
    {
      description: 'Created issues',
      category: 'issues',
      action: 'create',
      label_description: 'API',
      property_description: 'The string "issue_id"',
      value_description: 'ID of the issue',
      extra_properties: { confidential: false },
      product_group: 'group::product analytics',
      tiers: %w[free premium ultimate],
      introduced_by_url: "https://gitlab.com/example/-/merge_requests/123",
      milestone: '1.6'
    }
  end

  let(:path) { File.join('events', 'issues_create.yml') }
  let(:definition) { Gitlab::Tracking::EventDefinition.new(path, attributes) }

  describe '#validate' do
    using RSpec::Parameterized::TableSyntax

    where(:attribute, :value) do
      :description          | 1
      :category             | nil
      :action               | nil
      :label_description    | 1
      :property_description | 1
      :value_description    | 1
      :extra_properties     | 'smth'
      :product_group        | nil
      :tiers                | %(pro)
      :product_categories     | 'bad_category'
      :product_categories     | ['bad_category']
    end

    with_them do
      before do
        attributes[attribute] = value
      end

      it 'has validation errors' do
        expect(described_class.new(definition).validation_errors).not_to be_empty
      end
    end

    describe 'internal event additional_properties' do
      let(:attributes) do
        {
          description: 'Created issues',
          category: 'issues',
          action: 'create',
          internal_events: true,
          product_group: 'activation',
          introduced_by_url: "https://gitlab.com/example/-/merge_requests/123",
          milestone: "1.0",
          tiers: %w[free],
          additional_properties: {}
        }
      end

      where(:label, :property, :value, :custom, :error?) do
        true  | true  | true  | true  | false
        true  | true  | true  | false | false
        true  | true  | false | true  | false
        true  | true  | false | false | false
        true  | false | true  | true  | false
        true  | false | true  | false | false
        true  | false | false | true  | true
        true  | false | false | false | false
        false | true  | true  | true  | false
        false | true  | true  | false | false
        false | true  | false | true  | true
        false | true  | false | false | false
        false | false | true  | true  | false
        false | false | true  | false | false
        false | false | false | true  | true
        false | false | false | false | false
        nil   | nil   | nil   | nil   | false
      end

      with_them do
        before do
          attributes[:additional_properties][:label] = { description: "login button" } if label
          attributes[:additional_properties][:property] = { description: "button state" } if property
          attributes[:additional_properties][:value] = { description: "package version" } if value
          attributes[:additional_properties][:custom] = { description: "custom" } if custom

          attributes.delete(:additional_properties) if [label, property, value, custom].all?(&:nil?)
        end

        subject { described_class.new(definition).validation_errors.any? }

        it { is_expected.to be(error?) }
      end
    end
  end
end
