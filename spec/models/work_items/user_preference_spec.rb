# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::UserPreference, type: :model, feature_category: :team_planning do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to belong_to(:work_item_type).class_name('WorkItems::Type').inverse_of(:user_preferences) }
  end

  describe 'validations' do
    let_it_be(:namespace) { build_stubbed(:group) }

    describe 'validate sort' do
      let_it_be(:sorting_value) { 'due_date_asc' }

      it 'is valid when the sorting value is available' do
        preferences = described_class.new(namespace: namespace, sort: sorting_value)

        expect(WorkItems::SortingKeys)
          .to receive(:available?).with(sorting_value, widget_list: nil)
            .and_return(true)

        expect(preferences).to be_valid
      end

      it 'is not valid when the sorting value is not available' do
        preferences = described_class.new(namespace: namespace, sort: sorting_value)

        expect(WorkItems::SortingKeys)
          .to receive(:available?).with(sorting_value, widget_list: nil)
            .and_return(false)

        expect(preferences).not_to be_valid
        expect(preferences.errors.full_messages_for(:sort)).to include(
          %(Sort value "#{sorting_value}" is not available on #{namespace.full_path})
        )
      end

      it 'is not valid when the sorting value is not available for an existign work item type' do
        work_item_type = WorkItems::Type.default_by_type(:incident)
        preferences = described_class.new(
          namespace: namespace,
          work_item_type: work_item_type,
          sort: sorting_value
        )

        expect(WorkItems::SortingKeys)
          .to receive(:available?).with(
            sorting_value,
            widget_list: work_item_type.widget_classes(namespace)
          ).and_return(false)

        expect(preferences).not_to be_valid
        expect(preferences.errors.full_messages_for(:sort)).to include(<<~MESSAGE.squish)
          Sort value "#{sorting_value}" is not available
          on #{namespace.full_path} for work items type #{work_item_type.name}
        MESSAGE
      end
    end

    describe 'validate display_settings' do
      before do
        allow(WorkItems::SortingKeys).to receive(:available?).and_return(true)
      end

      it 'is valid with an empty display settings hash' do
        preferences = described_class.new(namespace: namespace, display_settings: {})

        expect(preferences).to be_valid
      end

      it 'is invalid with properties not defined in the schema' do
        invalid_display_settings = { 'invalidProperty' => 'some_value' }
        preferences = described_class.new(namespace: namespace, display_settings: invalid_display_settings)

        expect(preferences).not_to be_valid
        expect(preferences.errors[:display_settings]).to include('must be a valid json schema')
      end

      context 'with hiddenMetadataKeys property' do
        it 'is valid with an empty hiddenMetadataKeys array' do
          valid_display_settings = { 'hiddenMetadataKeys' => [] }
          preferences = described_class.new(namespace: namespace, display_settings: valid_display_settings)

          expect(preferences).to be_valid
        end

        it 'is valid with valid metadata keys in hiddenMetadataKeys' do
          valid_display_settings = {
            'hiddenMetadataKeys' => %w[assignee blocked blocking dates health labels milestone popularity weight
              comments iteration status]
          }
          preferences = described_class.new(namespace: namespace, display_settings: valid_display_settings)

          expect(preferences).to be_valid
          expect(preferences.display_settings['hiddenMetadataKeys']).to contain_exactly('assignee', 'blocked',
            'blocking', 'dates', 'health', 'labels', 'milestone', 'popularity', 'weight', 'comments', 'iteration',
            'status')
        end

        it 'is valid with all available metadata keys' do
          all_metadata_keys = %w[
            assignee blocked blocking dates health
            labels milestone popularity weight comments iteration status
          ]
          valid_display_settings = { 'hiddenMetadataKeys' => all_metadata_keys }
          preferences = described_class.new(namespace: namespace, display_settings: valid_display_settings)

          expect(preferences).to be_valid
        end

        it 'is invalid with invalid metadata keys' do
          invalid_display_settings = {
            'hiddenMetadataKeys' => %w[assignee invalid_key]
          }
          preferences = described_class.new(namespace: namespace, display_settings: invalid_display_settings)

          expect(preferences).not_to be_valid
          expect(preferences.errors[:display_settings]).to include('must be a valid json schema')
        end
      end
    end
  end
end
