# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Memory::Reports::HeapDump, feature_category: :cloud_connector do
  # Copy this class so we do not mess with its state.
  let(:klass) { described_class.dup }

  subject(:report) { klass.new }

  describe '#name' do
    # This is a bit silly, but it caused code coverage failures.
    it 'is set' do
      expect(report.name).to eq('heap_dump')
    end
  end

  describe '#active?' do
    it 'is true when report_heap_dumps is enabled' do
      expect(report).to be_active
    end

    it 'is false when report_heap_dumps is disabled' do
      stub_feature_flags(report_heap_dumps: false)

      expect(report).not_to be_active
    end
  end

  describe '#run' do
    subject(:run) { report.run(writer) }

    let(:writer) { StringIO.new }

    before do
      klass.remove_instance_variable(:@write_heap_dump) if klass.instance_variable_defined?(:@write_heap_dump)
    end

    context 'when no heap dump is enqueued' do
      it 'does nothing and returns false' do
        expect(ObjectSpace).not_to receive(:dump_all)

        expect(run).to be(false)
      end
    end

    context 'when a heap dump is enqueued', :aggregate_failures do
      it 'dumps heap and returns true' do
        expect(ObjectSpace).to receive(:dump_all).with(output: writer) do |output:|
          output << 'heap contents'
        end

        klass.enqueue!

        expect(run).to be(true)
        expect(writer.string).to eq('heap contents')
      end
    end
  end
end
