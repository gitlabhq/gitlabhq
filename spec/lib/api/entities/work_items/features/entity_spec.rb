# frozen_string_literal: true

require 'spec_helper'

# Features not yet implemented in the REST API
UNIMPLEMENTED_FEATURES = %w[
  agent_plan ai_session crm_contacts current_user_todos
  email_participants linked_resources notes participants test_reports vulnerabilities
].freeze

# linked_items and custom_fields are only exposed via the EE prepend on Features::Entity. In
# FOSS-only test runs the prepend doesn't apply, so add them to the exception list for that
# context only.
FOSS_ONLY_UNIMPLEMENTED_FEATURES = Gitlab.ee? ? [] : %w[linked_items custom_fields].freeze

RSpec.describe API::Entities::WorkItems::Features::Entity, feature_category: :team_planning do
  let(:requested_features) { [] }
  let(:work_item) { build(:work_item, description: 'Add keyboard shortcut support') }

  it_behaves_like 'work item widget entity parity',
    described_class,
    Types::WorkItems::FeaturesType,
    exceptions: UNIMPLEMENTED_FEATURES + FOSS_ONLY_UNIMPLEMENTED_FEATURES

  subject(:representation) do
    described_class
      .new(work_item, requested_features: requested_features)
      .as_json
  end

  shared_examples 'omits feature payload' do |feature|
    it "does not include the #{feature} payload" do
      expect(representation).not_to have_key(feature)
    end
  end

  context 'when the description feature is requested' do
    let(:requested_features) { [:description] }
    let(:description_widget) { WorkItems::Widgets::Description.new(work_item) }

    before do
      allow(work_item).to receive(:has_widget?).and_return(true)
      allow(work_item).to receive(:get_widget).with(:description).and_return(description_widget)
    end

    it 'includes the feature payload' do
      expect(representation).to include(
        description: a_hash_including(description: 'Add keyboard shortcut support')
      )
    end
  end

  context 'when no features are requested' do
    it_behaves_like 'omits feature payload', :description
  end

  context 'when the requested feature is unavailable' do
    let(:requested_features) { [:description] }

    before do
      allow(work_item).to receive(:has_widget?).and_return(false)
    end

    it_behaves_like 'omits feature payload', :description
  end

  describe 'milestone feature' do
    let(:requested_features) { [:milestone] }
    let(:widget_available) { true }
    let(:exposed_milestone) { build(:milestone) }
    let(:widget_instance) { instance_double(WorkItems::Widgets::Milestone, milestone: exposed_milestone) }

    before do
      allow(work_item).to receive(:has_widget?) { |widget| widget == :milestone && widget_available }
      allow(work_item).to receive(:get_widget).with(:milestone).and_return(widget_instance)
    end

    context 'when the widget exposes a milestone' do
      it 'includes the milestone payload' do
        expect(representation).to include(:milestone)
        expect(representation[:milestone]).to include(title: exposed_milestone.title)
      end
    end

    context 'when the widget exposes a nil milestone' do
      let(:exposed_milestone) { nil }

      it 'exposes the milestone key with a nil value' do
        expect(representation).to include(milestone: nil)
      end
    end

    context 'when the widget is present but returns nil' do
      let(:widget_instance) { nil }

      it 'exposes the milestone key with a nil value' do
        expect(representation).to include(milestone: nil)
      end
    end

    context 'when the widget is unavailable' do
      let(:widget_available) { false }
      let(:widget_instance) { nil }

      it 'omits the milestone payload' do
        expect(representation).not_to have_key(:milestone)
      end
    end
  end

  describe 'hierarchy feature' do
    let(:requested_features) { [:hierarchy] }
    let(:widget_available) { true }
    let(:parent) { nil }
    let(:widget_instance) { instance_double(WorkItems::Widgets::Hierarchy, parent: parent) }

    before do
      allow(work_item).to receive(:has_widget?) { |widget| widget == :hierarchy && widget_available }
      allow(work_item).to receive(:get_widget).with(:hierarchy).and_return(widget_instance)
    end

    it 'includes the hierarchy payload with no parent' do
      expect(representation).to include(hierarchy: a_hash_including(parent: nil, has_parent: false))
    end

    context 'when the widget is unavailable' do
      let(:widget_available) { false }
      let(:widget_instance) { nil }

      it 'omits the hierarchy payload' do
        expect(representation).not_to have_key(:hierarchy)
      end
    end
  end

  describe 'development feature' do
    let(:work_item) { build_stubbed(:work_item) }
    let(:requested_features) { [:development] }

    subject(:representation) do
      described_class
        .new(work_item, requested_features: requested_features, closing_merge_requests_counts: counts)
        .as_json
    end

    context 'when a closing merge requests count is preloaded for the work item' do
      let(:counts) { { work_item.id => 3 } }

      it 'exposes the preloaded count' do
        expect(representation).to include(development: a_hash_including(closing_merge_requests_count: 3))
      end
    end

    context 'when no count is preloaded for the work item' do
      let(:counts) { {} }

      it 'defaults the count to zero' do
        expect(representation).to include(development: a_hash_including(closing_merge_requests_count: 0))
      end
    end

    context 'when no counts hash is passed in options' do
      subject(:representation) do
        described_class.new(work_item, requested_features: requested_features).as_json
      end

      it 'defaults the count to zero' do
        expect(representation).to include(development: a_hash_including(closing_merge_requests_count: 0))
      end
    end

    context 'when the work item does not have the development widget' do
      let(:counts) { {} }

      before do
        # No FOSS work item type lacks the development widget, so stub the guard rather than couple
        # the test to an EE-only type.
        allow(work_item).to receive(:has_widget?).with(:development).and_return(false)
      end

      it 'omits the development payload' do
        expect(representation).not_to have_key(:development)
      end
    end
  end
end
