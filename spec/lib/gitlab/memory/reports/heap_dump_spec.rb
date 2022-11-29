# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Memory::Reports::HeapDump do
  # Copy this class so we do not mess with its state.
  let(:klass) { described_class.dup }

  subject(:report) { klass.new }

  describe '#name' do
    # This is a bit silly, but it caused code coverage failures.
    it 'is set' do
      expect(report.name).to eq('heap_dump')
    end
  end

  describe '#run' do
    subject(:run) { report.run(writer) }

    let(:writer) { StringIO.new }

    context 'when no heap dump is enqueued' do
      it 'does nothing and returns false' do
        expect(run).to be(false)
      end
    end

    context 'when a heap dump is enqueued' do
      it 'does nothing and returns true' do
        klass.enqueue!

        expect(run).to be(true)
      end
    end
  end
end
