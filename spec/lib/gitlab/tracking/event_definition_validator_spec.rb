# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Tracking::EventDefinitionValidator, feature_category: :service_ping do
  using RSpec::Parameterized::TableSyntax

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
      :status                 | 'destroyed'
      :removed_by_url         | 'non/url'
      :milestone_removed      | 'a.b.c'
    end

    with_them do
      before do
        attributes[attribute] = value
      end

      it 'has validation errors' do
        expect(described_class.new(definition).validation_errors).not_to be_empty
      end
    end

    describe 'status' do
      let(:attributes) do
        {
          description: 'Created issues',
          category: 'issues',
          action: 'create',
          internal_events: true,
          product_group: 'activation',
          introduced_by_url: "https://gitlab.com/example/-/merge_requests/123",
          milestone: "1.0",
          tiers: %w[free]
        }
      end

      where(:status, :milestone_removed, :removed_by_url, :error?) do
        'active' | nil           | nil | false
        'removed' | '1.0'        | 'https://gitlab.com/example/-/merge_requests/123' | false
        'removed' | nil          | 'https://gitlab.com/example/-/merge_requests/123' | true
        'removed' | '1.0'        | nil           | true
        'removed' | nil          | nil           | true
        'active'  | '1.0'        | nil           | true
        'active'  | nil          | 'https://gitlab.com/example/-/merge_requests/123' | true
      end

      with_them do
        before do
          attributes[:status] = status
          attributes[:milestone_removed] = milestone_removed if milestone_removed
          attributes[:removed_by_url] = removed_by_url if removed_by_url
        end

        subject { described_class.new(definition).validation_errors.any? }

        it { is_expected.to be(error?) }
      end
    end
  end
end
