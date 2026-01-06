# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::WorkItems::Instrumentation::EventMappings, feature_category: :portfolio_management do
  describe 'ATTRIBUTE_MAPPINGS' do
    it 'has valid structure' do
      described_class::ATTRIBUTE_MAPPINGS.each do |mapping|
        expect(mapping).to have_key(:event)
        expect(mapping).to have_key(:key)
        expect(mapping[:key]).to be_a(String)

        expect(mapping[:event]).to satisfy do |event|
          event.is_a?(String) || event.respond_to?(:call)
        end
      end
    end

    describe 'callable events' do
      it 'correctly handles discussion_locked changes' do
        mapping = described_class::ATTRIBUTE_MAPPINGS.find { |m| m[:key] == 'discussion_locked' }

        expect(mapping).not_to be_nil
        expect(mapping[:event]).to respond_to(:call)

        expect(mapping[:event].call([false, true])).to eq(Gitlab::WorkItems::Instrumentation::EventActions::LOCK)
        expect(mapping[:event].call([true, false])).to eq(Gitlab::WorkItems::Instrumentation::EventActions::UNLOCK)
        expect(mapping[:event].call([false, false])).to eq(Gitlab::WorkItems::Instrumentation::EventActions::UNLOCK)
        expect(mapping[:event].call([true, true])).to eq(Gitlab::WorkItems::Instrumentation::EventActions::LOCK)
      end
    end
  end

  describe 'ASSOCIATION_MAPPINGS' do
    it 'has valid structure' do
      described_class::ASSOCIATION_MAPPINGS.each do |mapping|
        expect(mapping).to have_key(:event)
        expect(mapping).to have_key(:key)
        expect(mapping).to have_key(:compare)
        expect(mapping[:key]).to be_a(Symbol)
        expect(mapping[:compare]).to respond_to(:call)
      end
    end

    describe 'compare functions' do
      it 'correctly compares assignees' do
        mapping = described_class::ASSOCIATION_MAPPINGS.find { |m| m[:key] == :assignees }

        expect(mapping[:compare].call([1, 2], [1, 2])).to be false
        expect(mapping[:compare].call([1, 2], [2, 1])).to be true
        expect(mapping[:compare].call([], [1])).to be true
      end

      it 'correctly detects confidentiality enable' do
        mapping = described_class::ASSOCIATION_MAPPINGS.find do |m|
          m[:event] == Gitlab::WorkItems::Instrumentation::EventActions::CONFIDENTIALITY_ENABLE
        end

        expect(mapping[:compare].call(false, true)).to be true
        expect(mapping[:compare].call(true, false)).to be false
        expect(mapping[:compare].call(false, false)).to be false
        expect(mapping[:compare].call(true, true)).to be false
      end

      it 'correctly detects confidentiality disable' do
        mapping = described_class::ASSOCIATION_MAPPINGS.find do |m|
          m[:event] == Gitlab::WorkItems::Instrumentation::EventActions::CONFIDENTIALITY_DISABLE
        end

        expect(mapping[:compare].call(true, false)).to be true
        expect(mapping[:compare].call(false, true)).to be false
        expect(mapping[:compare].call(false, false)).to be false
        expect(mapping[:compare].call(true, true)).to be false
      end
    end
  end

  describe '.events_for' do
    let(:work_item) { instance_double(WorkItem) }
    let(:old_associations) { {} }
    let(:previous_changes) { {} }

    before do
      allow(work_item).to receive(:previous_changes).and_return(previous_changes)
    end

    subject(:events) { described_class.events_for(work_item: work_item, old_associations: old_associations) }

    context 'with no changes' do
      it 'returns an empty array' do
        expect(events).to eq([])
      end
    end

    context 'with attribute changes' do
      [
        %w[title work_item_title_update],
        %w[description work_item_description_update],
        %w[milestone_id work_item_milestone_update],
        %w[weight work_item_weight_update],
        %w[sprint_id work_item_iteration_update],
        %w[health_status work_item_health_status_update],
        %w[due_date work_item_due_date_update],
        %w[start_date work_item_start_date_update],
        %w[time_estimate work_item_time_estimate_update]
      ].each do |attribute, event_name|
        context "when #{attribute} changes" do
          let(:previous_changes) { { attribute => %w[old new] } }

          it "returns #{event_name}" do
            expect(events).to contain_exactly(event_name)
          end
        end
      end

      context 'when discussion_locked changes' do
        context 'when discussion is locked' do
          let(:previous_changes) { { 'discussion_locked' => [false, true] } }

          it 'returns work_item_lock' do
            expect(events).to contain_exactly(Gitlab::WorkItems::Instrumentation::EventActions::LOCK)
          end
        end

        context 'when discussion is unlocked' do
          let(:previous_changes) { { 'discussion_locked' => [true, false] } }

          it 'returns work_item_unlock' do
            expect(events).to contain_exactly(Gitlab::WorkItems::Instrumentation::EventActions::UNLOCK)
          end
        end
      end

      context 'when event callable returns nil' do
        before do
          stub_const('Gitlab::WorkItems::Instrumentation::EventMappings::ATTRIBUTE_MAPPINGS', [
            {
              event: ->(_change) { nil },
              key: 'test_attribute'
            }
          ])
        end

        let(:previous_changes) { { 'test_attribute' => %w[old new] } }

        it 'does not add nil events to the result' do
          expect(events).to eq([])
        end
      end
    end

    context 'with association changes' do
      context 'when assignees change' do
        let(:old_associations) { { assignees: ['user1'] } }

        before do
          allow(work_item).to receive(:assignees).and_return(['user2'])
        end

        it 'returns work_item_assignees_update' do
          expect(events).to contain_exactly('work_item_assignees_update')
        end
      end

      context 'when assignees do not change' do
        let(:value) { ['user1'] }
        let(:old_associations) { { assignees: value } }

        before do
          allow(work_item).to receive(:assignees).and_return(value)
        end

        it 'returns empty array' do
          expect(events).to eq([])
        end
      end

      context 'when confidential changes' do
        context 'when work item is set to confidential: false' do
          let(:old_associations) { { confidential: false } }

          before do
            allow(work_item).to receive(:confidential).and_return(true)
          end

          it 'returns work_item_confidentiality_enable' do
            expect(events).to contain_exactly('work_item_confidentiality_enable')
          end
        end

        context 'when work item is set to confidential: true' do
          let(:old_associations) { { confidential: true } }

          before do
            allow(work_item).to receive(:confidential).and_return(false)
          end

          it 'returns work_item_confidentiality_disable' do
            expect(events).to contain_exactly('work_item_confidentiality_disable')
          end
        end
      end

      context 'when labels change' do
        let(:old_associations) { { labels: ['bug'] } }

        before do
          allow(work_item).to receive(:labels).and_return(%w[bug feature])
        end

        it 'returns work_item_labels_update' do
          expect(events).to contain_exactly('work_item_labels_update')
        end
      end

      context 'when total_time_spent changes' do
        let(:old_associations) { { total_time_spent: 1800 } }

        before do
          allow(work_item).to receive(:total_time_spent).and_return(3600)
        end

        it 'returns work_item_time_spent_update' do
          expect(events).to contain_exactly('work_item_time_spent_update')
        end
      end
    end

    context 'with multiple simultaneous changes' do
      let(:previous_changes) { { 'title' => %w[old new], 'description' => %w[old new] } }
      let(:old_associations) { { assignees: ['user1'] } }

      before do
        allow(work_item).to receive(:assignees).and_return(['user2'])
      end

      it 'returns all relevant events' do
        expect(events).to contain_exactly(
          'work_item_title_update',
          'work_item_description_update',
          'work_item_assignees_update'
        )
      end
    end
  end
end
