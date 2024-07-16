# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Peek::Views::DetailedView, :request_store do
  context 'when a class defines thresholds' do
    let(:threshold_view) do
      Class.new(described_class) do
        def self.thresholds
          {
            calls: 1,
            duration: 10,
            individual_call: 5
          }
        end

        def key
          'threshold-view'
        end
      end.new
    end

    context 'when the results exceed the calls threshold' do
      before do
        allow(threshold_view)
          .to receive(:detail_store).and_return([{ duration: 0.001 }, { duration: 0.001 }])
      end

      it 'adds a warning to the results key' do
        expect(threshold_view.results).to include(warnings: [a_string_matching('threshold-view calls')])
      end
    end

    context 'when the results exceed the duration threshold' do
      before do
        allow(threshold_view)
          .to receive(:detail_store).and_return([{ duration: 0.011 }])
      end

      it 'adds a warning to the results key' do
        expect(threshold_view.results).to include(warnings: [a_string_matching('threshold-view duration')])
      end
    end

    context 'when a single call exceeds the duration threshold' do
      before do
        allow(threshold_view)
          .to receive(:detail_store).and_return([{ duration: 0.001 }, { duration: 0.006 }])
      end

      it 'adds a warning to that call detail entry' do
        expect(threshold_view.results)
          .to include(details: a_collection_containing_exactly(
            { duration: 1.0, warnings: [] },
            { duration: 6.0, warnings: ['6.0 over 5'] }
          ))
      end
    end
  end

  context 'when a view does not define thresholds' do
    let(:no_threshold_view) { Class.new(described_class).new }

    before do
      allow(no_threshold_view)
        .to receive(:detail_store).and_return([{ duration: 100 }, { duration: 100 }])
    end

    it 'does not add warnings to the top level' do
      expect(no_threshold_view.results).to include(warnings: [])
    end

    it 'does not add warnings to call details entries' do
      expect(no_threshold_view.results)
        .to include(details: a_collection_containing_exactly(
          { duration: 100000, warnings: [] },
          { duration: 100000, warnings: [] }
        ))
    end
  end
end
