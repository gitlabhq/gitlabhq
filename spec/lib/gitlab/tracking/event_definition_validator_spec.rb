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
      distributions: %w[ee ce],
      tiers: %w[free premium ultimate],
      introduced_by_url: "https://gitlab.com/example/-/merge_requests/123",
      milestone: '1.6'
    }
  end

  let(:path) { File.join('events', 'issues_create.yml') }
  let(:definition) { Gitlab::Tracking::EventDefinition.new(path, attributes) }
  # let(:yaml_content) { attributes.deep_stringify_keys.to_yaml }

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
      :distributions        | %(be eb)
      :tiers                | %(pro)
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
          distributions: %w[ce],
          milestone: "1.0",
          tiers: %w[free],
          additional_properties: {
            label: { description: "desc" },
            property: { description: "desc" }
          }
        }
      end

      it 'valid when extra added in addition to the built in' do
        attributes[:additional_properties][:extra] = { description: "desc" }

        expect(described_class.new(definition).validation_errors).to be_empty
      end

      it 'invalid when extra added with no built in used' do
        attributes[:additional_properties] = { extra: { description: "desc" } }

        expect(described_class.new(definition).validation_errors).not_to be_empty
      end
    end
  end
end
