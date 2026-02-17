# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WorkItems::Features::Entity, feature_category: :team_planning do
  let(:work_item) { build(:work_item, description: 'Add keyboard shortcut support') }
  let(:requested_features) { [] }

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
        expect(representation).to include(milestone: a_hash_including(title: exposed_milestone.title))
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
end
