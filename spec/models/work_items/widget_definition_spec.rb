# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::WidgetDefinition, feature_category: :team_planning do
  let(:all_widget_classes) do
    list = [
      ::WorkItems::Widgets::Description,
      ::WorkItems::Widgets::Hierarchy,
      ::WorkItems::Widgets::Labels,
      ::WorkItems::Widgets::Assignees,
      ::WorkItems::Widgets::StartAndDueDate,
      ::WorkItems::Widgets::Milestone,
      ::WorkItems::Widgets::Notes,
      ::WorkItems::Widgets::Notifications,
      ::WorkItems::Widgets::CurrentUserTodos,
      ::WorkItems::Widgets::AwardEmoji,
      ::WorkItems::Widgets::LinkedItems,
      ::WorkItems::Widgets::LinkedResources,
      ::WorkItems::Widgets::Participants,
      ::WorkItems::Widgets::TimeTracking,
      ::WorkItems::Widgets::Designs,
      ::WorkItems::Widgets::Development,
      ::WorkItems::Widgets::CrmContacts,
      ::WorkItems::Widgets::EmailParticipants,
      ::WorkItems::Widgets::ErrorTracking
    ]

    if Gitlab.ee?
      list += [
        ::WorkItems::Widgets::Iteration,
        ::WorkItems::Widgets::Weight,
        ::WorkItems::Widgets::VerificationStatus,
        ::WorkItems::Widgets::HealthStatus,
        ::WorkItems::Widgets::Progress,
        ::WorkItems::Widgets::RequirementLegacy,
        ::WorkItems::Widgets::TestReports,
        ::WorkItems::Widgets::Color,
        ::WorkItems::Widgets::CustomFields,
        ::WorkItems::Widgets::Vulnerabilities,
        ::WorkItems::Widgets::Status
      ]
    end

    list
  end

  describe 'associations' do
    it { is_expected.to belong_to(:work_item_type) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }

    it { is_expected.to validate_length_of(:name).is_at_most(255) }

    describe 'name uniqueness' do
      let_it_be(:test_type) { create(:work_item_type, :non_default, name: 'Test Type') }
      let_it_be(:existing_widget) { create(:widget_definition, name: 'TesT Widget', work_item_type: test_type) }

      it 'validates uniqueness with a custom validator' do
        new_widget = build(:widget_definition, name: ' TesT WIDGET ', work_item_type: test_type)
        expect(new_widget).to be_invalid
        expect(new_widget.errors.full_messages).to include('Name has already been taken')
      end
    end

    describe 'widget_options' do
      subject(:widget_definition) do
        build(:widget_definition, widget_type: widget_type, widget_options: widget_options)
      end

      context 'when widget type is weight' do
        let(:widget_type) { 'weight' }

        context 'when widget_options has valid attributes' do
          let(:widget_options) { { editable: true, rollup: false } }

          it { is_expected.to be_valid }
        end

        context 'when widget_options is nil' do
          let(:widget_options) { nil }

          it { is_expected.to be_invalid }
        end

        context 'when widget_options has invalid attributes' do
          let(:widget_options) { { other_key: :other_value } }

          it { is_expected.to be_invalid }
        end
      end

      context 'when widget type is something else' do
        let(:widget_type) { 'labels' }

        context 'when widget_options is nil' do
          let(:widget_options) { nil }

          it { is_expected.to be_valid }
        end

        context 'when widget_options is not empty' do
          let(:widget_options) { { editable: true, rollup: false } }

          it { is_expected.to be_invalid }
        end
      end
    end
  end

  context 'with some widgets disabled' do
    before do
      described_class.where(widget_type: :notes).update_all(disabled: true)
    end

    describe '.available_widgets' do
      subject { described_class.available_widgets }

      it 'returns all widgets excluding the disabled ones' do
        is_expected.to match_array(all_widget_classes - [::WorkItems::Widgets::Notes])
      end

      it 'returns all widgets if there is at least one widget definition which is enabled' do
        create(:widget_definition, widget_type: :notes)

        is_expected.to match_array(all_widget_classes)
      end
    end

    describe '.widget_classes' do
      subject { described_class.widget_classes }

      it 'returns all widget classes no matter if disabled or not' do
        is_expected.to match_array(all_widget_classes)
      end
    end
  end

  describe '#widget_class' do
    it 'returns widget class based on widget_type' do
      expect(build(:widget_definition, widget_type: :description).widget_class).to eq(::WorkItems::Widgets::Description)
    end

    it 'returns nil if there is no class for the widget_type' do
      described_class.first.update_column(:widget_type, -1)

      expect(described_class.first.widget_class).to be_nil
    end

    it 'returns nil if there is no class for the widget_type' do
      expect(build(:widget_definition, widget_type: nil).widget_class).to be_nil
    end
  end

  describe 'widget_type enum stability' do
    it 'maintains stable enum values for existing widget types' do
      expected_enum_values = {
        "assignees" => 0,
        "description" => 1,
        "hierarchy" => 2,
        "labels" => 3,
        "milestone" => 4,
        "notes" => 5,
        "start_and_due_date" => 6,
        "health_status" => 7,
        "weight" => 8,
        "iteration" => 9,
        "progress" => 10,
        "verification_status" => 11,
        "requirement_legacy" => 12,
        "test_reports" => 13,
        "notifications" => 14,
        "current_user_todos" => 15,
        "award_emoji" => 16,
        "linked_items" => 17,
        "color" => 18,
        "participants" => 20,
        "time_tracking" => 21,
        "designs" => 22,
        "development" => 23,
        "crm_contacts" => 24,
        "email_participants" => 25,
        "status" => 26,
        "linked_resources" => 27,
        "custom_fields" => 28,
        "error_tracking" => 29,
        "vulnerabilities" => 30
      }

      expect(described_class.widget_types).to eq(expected_enum_values)
    end
  end
end
