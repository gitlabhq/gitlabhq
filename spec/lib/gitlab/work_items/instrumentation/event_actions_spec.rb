# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::WorkItems::Instrumentation::EventActions, feature_category: :portfolio_management do
  describe 'event constants' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:namespace) { project.namespace }

    described_class.constants.each do |constant_name|
      next if constant_name == :ALL_EVENTS

      event_name = described_class.const_get(constant_name, false)

      it "defines a valid internal event for #{constant_name} ('#{event_name}')" do
        expect do
          Gitlab::InternalEvents.track_event(event_name, user: user, project: project, namespace: namespace)
        end.not_to raise_error
      end
    end
  end

  describe 'ALL_EVENTS' do
    let(:individual_event_constants) do
      described_class.constants - [:ALL_EVENTS]
    end

    let(:individual_event_values) do
      individual_event_constants.map { |c| described_class.const_get(c, false) }
    end

    it 'contains each event constant value exactly once' do
      expect(described_class::ALL_EVENTS).to match_array(individual_event_values)
    end

    it 'has no duplicates' do
      expect(described_class::ALL_EVENTS).to eq(described_class::ALL_EVENTS.uniq)
    end

    it 'is frozen to prevent modification' do
      expect(described_class::ALL_EVENTS).to be_frozen
    end

    it 'includes all non-ALL_EVENTS constants' do
      individual_event_values.each do |event|
        expect(described_class::ALL_EVENTS).to include(event)
      end
    end
  end

  describe 'constant values' do
    it 'has unique event names for all constants' do
      event_names = described_class.constants
                      .reject { |c| c == :ALL_EVENTS }
                      .map { |c| described_class.const_get(c, false) }
      expect(event_names).to eq(event_names.uniq)
    end
  end

  describe '.valid_event?' do
    context 'with valid events' do
      it 'returns true for all defined event constants' do
        described_class::ALL_EVENTS.each do |event_name|
          expect(described_class.valid_event?(event_name)).to be true
        end
      end
    end

    context 'with invalid events' do
      it 'returns false for unknown event names' do
        expect(described_class.valid_event?('unknown_event')).to be false
      end

      it 'returns false for nil' do
        expect(described_class.valid_event?(nil)).to be false
      end
    end
  end
end
