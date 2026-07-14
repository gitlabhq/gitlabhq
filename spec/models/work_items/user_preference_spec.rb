# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::UserPreference, type: :model, feature_category: :team_planning do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:namespace) }
  end

  describe 'validations' do
    let_it_be(:namespace) { build_stubbed(:group) }
    let_it_be(:user) { create(:user) }
    let(:work_item_type) { build(:work_item_system_defined_type, :issue) }

    describe 'validate work_item_type_id' do
      subject(:user_preference) do
        build(:work_item_user_preference, user: user, namespace: namespace, work_item_type_id: work_item_type.id)
      end

      it_behaves_like 'validates work item type ID'

      context 'when work_item_type_id is nil' do
        it 'is valid' do
          user_preference.work_item_type_id = nil
          expect(user_preference).to be_valid
        end
      end
    end

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
        work_item_type = build(:work_item_system_defined_type, :incident)
        preferences = described_class.new(
          namespace: namespace,
          work_item_type_id: work_item_type.id,
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

      context 'with collapsedGroups property' do
        it 'is valid with an empty collapsedGroups array' do
          preferences = described_class.new(namespace: namespace, display_settings: { 'collapsedGroups' => [] })

          expect(preferences).to be_valid
        end

        it 'is valid with group identifier strings', :aggregate_failures do
          valid_display_settings = {
            'collapsedGroups' => [
              'status:gid://gitlab/WorkItems::Statuses::SystemDefined::Status/1',
              'status:gid://gitlab/WorkItems::Statuses::Custom::Status/42'
            ]
          }
          preferences = described_class.new(namespace: namespace, display_settings: valid_display_settings)

          expect(preferences).to be_valid
          expect(preferences.display_settings['collapsedGroups']).to contain_exactly(
            'status:gid://gitlab/WorkItems::Statuses::SystemDefined::Status/1',
            'status:gid://gitlab/WorkItems::Statuses::Custom::Status/42'
          )
        end

        it 'is valid alongside hiddenMetadataKeys' do
          valid_display_settings = {
            'hiddenMetadataKeys' => %w[labels],
            'collapsedGroups' => %w[status:gid://gitlab/WorkItems::Statuses::Custom::Status/42]
          }
          preferences = described_class.new(namespace: namespace, display_settings: valid_display_settings)

          expect(preferences).to be_valid
        end

        it 'is invalid with duplicate group identifiers' do
          invalid_display_settings = { 'collapsedGroups' => %w[status:gid status:gid] }
          preferences = described_class.new(namespace: namespace, display_settings: invalid_display_settings)

          expect(preferences).not_to be_valid
          expect(preferences.errors[:display_settings]).to include('must be a valid json schema')
        end

        it 'is invalid with non-string group identifiers' do
          invalid_display_settings = { 'collapsedGroups' => [1] }
          preferences = described_class.new(namespace: namespace, display_settings: invalid_display_settings)

          expect(preferences).not_to be_valid
          expect(preferences.errors[:display_settings]).to include('must be a valid json schema')
        end

        it 'is invalid when more than 100 columns are collapsed' do
          invalid_display_settings = { 'collapsedGroups' => (1..101).map { |i| "status:#{i}" } }
          preferences = described_class.new(namespace: namespace, display_settings: invalid_display_settings)

          expect(preferences).not_to be_valid
          expect(preferences.errors[:display_settings]).to include('must be a valid json schema')
        end

        it 'is invalid when a group identifier exceeds the length limit' do
          invalid_display_settings = { 'collapsedGroups' => ["status:#{'a' * 256}"] }
          preferences = described_class.new(namespace: namespace, display_settings: invalid_display_settings)

          expect(preferences).not_to be_valid
          expect(preferences.errors[:display_settings]).to include('must be a valid json schema')
        end
      end

      context 'with visibleGroups property' do
        it 'is valid with an empty visibleGroups array' do
          preferences = described_class.new(namespace: namespace, display_settings: { 'visibleGroups' => [] })

          expect(preferences).to be_valid
        end

        it 'is valid with a null visibleGroups value' do
          preferences = described_class.new(namespace: namespace, display_settings: { 'visibleGroups' => nil })

          expect(preferences).to be_valid
        end

        it 'is valid with group identifier strings', :aggregate_failures do
          valid_display_settings = {
            'visibleGroups' => [
              'status:gid://gitlab/WorkItems::Statuses::SystemDefined::Status/1',
              'status:gid://gitlab/WorkItems::Statuses::Custom::Status/42'
            ]
          }
          preferences = described_class.new(namespace: namespace, display_settings: valid_display_settings)

          expect(preferences).to be_valid
          expect(preferences.display_settings['visibleGroups']).to contain_exactly(
            'status:gid://gitlab/WorkItems::Statuses::SystemDefined::Status/1',
            'status:gid://gitlab/WorkItems::Statuses::Custom::Status/42'
          )
        end

        it 'is valid alongside hiddenMetadataKeys and collapsedGroups' do
          valid_display_settings = {
            'hiddenMetadataKeys' => %w[labels],
            'collapsedGroups' => %w[status:gid://gitlab/WorkItems::Statuses::Custom::Status/42],
            'visibleGroups' => %w[status:gid://gitlab/WorkItems::Statuses::Custom::Status/42]
          }
          preferences = described_class.new(namespace: namespace, display_settings: valid_display_settings)

          expect(preferences).to be_valid
        end

        it 'is invalid with duplicate group identifiers' do
          invalid_display_settings = { 'visibleGroups' => %w[status:gid status:gid] }
          preferences = described_class.new(namespace: namespace, display_settings: invalid_display_settings)

          expect(preferences).not_to be_valid
          expect(preferences.errors[:display_settings]).to include('must be a valid json schema')
        end

        it 'is invalid with non-string group identifiers' do
          invalid_display_settings = { 'visibleGroups' => [1] }
          preferences = described_class.new(namespace: namespace, display_settings: invalid_display_settings)

          expect(preferences).not_to be_valid
          expect(preferences.errors[:display_settings]).to include('must be a valid json schema')
        end

        it 'is invalid when more than 100 groups are visible' do
          invalid_display_settings = { 'visibleGroups' => (1..101).map { |i| "status:#{i}" } }
          preferences = described_class.new(namespace: namespace, display_settings: invalid_display_settings)

          expect(preferences).not_to be_valid
          expect(preferences.errors[:display_settings]).to include('must be a valid json schema')
        end

        it 'is invalid when a group identifier exceeds the length limit' do
          invalid_display_settings = { 'visibleGroups' => ["status:#{'a' * 256}"] }
          preferences = described_class.new(namespace: namespace, display_settings: invalid_display_settings)

          expect(preferences).not_to be_valid
          expect(preferences.errors[:display_settings]).to include('must be a valid json schema')
        end
      end
    end
  end
end
