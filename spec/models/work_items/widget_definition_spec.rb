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
      ::WorkItems::Widgets::Participants,
      ::WorkItems::Widgets::TimeTracking,
      ::WorkItems::Widgets::Designs,
      ::WorkItems::Widgets::Development
    ]

    if Gitlab.ee?
      list += [
        ::WorkItems::Widgets::Iteration,
        ::WorkItems::Widgets::Weight,
        ::WorkItems::Widgets::Status,
        ::WorkItems::Widgets::HealthStatus,
        ::WorkItems::Widgets::Progress,
        ::WorkItems::Widgets::RequirementLegacy,
        ::WorkItems::Widgets::TestReports,
        ::WorkItems::Widgets::Color,
        ::WorkItems::Widgets::RolledupDates
      ]
    end

    list
  end

  describe 'associations' do
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to belong_to(:work_item_type) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive.scoped_to([:namespace_id, :work_item_type_id]) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
  end

  context 'with some widgets disabled' do
    before do
      described_class.global.where(widget_type: :notes).update_all(disabled: true)
    end

    describe '.available_widgets' do
      subject { described_class.available_widgets }

      it 'returns all global widgets excluding the disabled ones' do
        # WorkItems::Widgets::Notes is excluded from widget class because:
        # * although widget_definition below is enabled and uses notes widget, it's namespaced (has namespace != nil)
        # * available_widgets takes into account only global definitions (which have namespace=nil)
        namespace = create(:namespace)
        create(:widget_definition, namespace: namespace, widget_type: :notes)

        is_expected.to match_array(all_widget_classes - [::WorkItems::Widgets::Notes])
      end

      it 'returns all global widgets if there is at least one global widget definition which is enabled' do
        create(:widget_definition, namespace: nil, widget_type: :notes)

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
end
