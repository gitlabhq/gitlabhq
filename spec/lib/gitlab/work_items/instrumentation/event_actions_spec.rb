# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::WorkItems::Instrumentation::EventActions, feature_category: :team_planning do
  describe 'event constants' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:namespace) { project.namespace }

    described_class::WORK_ITEM_EVENTS.each do |event_name|
      it "defines a valid internal event for '#{event_name}'" do
        expect do
          Gitlab::InternalEvents.track_event(event_name, user: user, project: project, namespace: namespace)
        end.not_to raise_error
      end
    end
  end

  describe '.link_event' do
    let_it_be(:work_item) { create(:work_item, :task) }
    let_it_be(:other_work_item) { create(:work_item, :task) }

    context 'with relates_to link' do
      let(:link) { build(:work_item_link, link_type: 'relates_to') }

      it 'returns correct events for add and remove actions' do
        expect(described_class.link_event(link, work_item, :add))
          .to eq(described_class::RELATED_ITEM_ADD)
        expect(described_class.link_event(link, work_item, :remove))
          .to eq(described_class::RELATED_ITEM_REMOVE)
      end
    end

    context 'with blocks link' do
      it 'returns blocking events when work_item is source' do
        link = build(:work_item_link,
          source_id: work_item.id,
          target_id: other_work_item.id,
          link_type: 'blocks')

        expect(described_class.link_event(link, work_item, :add))
          .to eq(described_class::BLOCKING_ITEM_ADD)
        expect(described_class.link_event(link, work_item, :remove))
          .to eq(described_class::BLOCKING_ITEM_REMOVE)
      end

      it 'returns blocked_by events when work_item is target' do
        link = build(:work_item_link,
          source_id: other_work_item.id,
          target_id: work_item.id,
          link_type: 'blocks')

        expect(described_class.link_event(link, work_item, :add))
          .to eq(described_class::BLOCKED_BY_ITEM_ADD)
        expect(described_class.link_event(link, work_item, :remove))
          .to eq(described_class::BLOCKED_BY_ITEM_REMOVE)
      end

      context 'when work_item is neither source nor target' do
        let(:unrelated_work_item) { create(:work_item, :task) }
        let(:link) do
          build(:work_item_link,
            source_id: other_work_item.id,
            target_id: create(:work_item, :task).id,
            link_type: 'blocks')
        end

        it 'returns nil' do
          expect(described_class.link_event(link, unrelated_work_item, :add)).to be_nil
          expect(described_class.link_event(link, unrelated_work_item, :remove)).to be_nil
        end
      end
    end

    context 'with invalid action' do
      let(:link) { build(:work_item_link, link_type: 'relates_to') }

      it 'returns nil' do
        expect(described_class.link_event(link, work_item, :invalid)).to be_nil
        expect(described_class.link_event(link, work_item, 'add')).to be_nil
      end
    end
  end

  describe '.valid_work_item_event?' do
    it 'returns true for work item events' do
      expect(described_class.valid_work_item_event?(described_class::CREATE)).to be true
      expect(described_class.valid_work_item_event?(described_class::CLOSE)).to be true
    end

    it 'returns false for non-work item events' do
      expect(described_class.valid_work_item_event?(described_class::SAVED_VIEW_CREATE)).to be false
    end

    it 'returns false for unknown events' do
      expect(described_class.valid_work_item_event?('unknown_event')).to be false
      expect(described_class.valid_work_item_event?(nil)).to be false
    end
  end

  describe 'event arrays' do
    it 'has no duplicates in WORK_ITEM_EVENTS' do
      expect(described_class::WORK_ITEM_EVENTS).to eq(described_class::WORK_ITEM_EVENTS.uniq)
    end

    it 'freezes event arrays' do
      expect(described_class::WORK_ITEM_EVENTS).to be_frozen
    end
  end
end
