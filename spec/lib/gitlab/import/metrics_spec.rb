# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Import::Metrics do
  let(:importer_stub) do
    Class.new do
      prepend Gitlab::Import::Metrics

      Gitlab::Import::Metrics.measure :execute, metrics: {
        importer_counter:   {
          type: :counter,
          description: 'description'
        },
        importer_histogram: {
          type: :histogram,
          labels: { importer: 'importer' },
          description: 'description'
        }
      }

      def execute
        true
      end
    end
  end

  subject { importer_stub.new.execute }

  describe '#execute' do
    let(:counter) { double(:counter) }
    let(:histogram) { double(:histogram) }

    it 'increments counter metric' do
      expect(Gitlab::Metrics)
        .to receive(:counter)
              .with(:importer_counter, 'description')
              .and_return(counter)

      expect(counter).to receive(:increment)

      subject
    end

    it 'measures method duration and reports histogram metric' do
      expect(Gitlab::Metrics)
        .to receive(:histogram)
              .with(:importer_histogram, 'description')
              .and_return(histogram)

      expect(histogram).to receive(:observe).with({ importer: 'importer' }, anything)

      subject
    end
  end
end
