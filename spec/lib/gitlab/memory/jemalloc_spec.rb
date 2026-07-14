# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'

RSpec.describe Gitlab::Memory::Jemalloc, feature_category: :durability_metrics do
  let(:outfile) { Tempfile.new }
  let(:current_process) { instance_double(::FFI::DynamicLibrary) }

  after do
    outfile.close
    outfile.unlink
  end

  before do
    allow(::FFI::DynamicLibrary).to receive(:open).and_return(current_process)
    # The stats callback is a real FFI::Function built from a block; only the
    # malloc_stats_print lookup is stubbed (see #stub_stats_call).
    allow(::FFI::Function).to receive(:new).and_call_original
  end

  context 'when jemalloc is loaded' do
    let(:stats_print) { instance_double(::FFI::Function) }

    context 'with JSON format' do
      let(:format) { :json }
      let(:output) { '{"a": 24}' }

      before do
        stub_stats_call(output, 'J')
      end

      describe '.stats' do
        it 'returns stats JSON' do
          expect(described_class.stats(format: format)).to eq(output)
        end
      end

      describe '.dump_stats' do
        it 'writes stats JSON file' do
          described_class.dump_stats(outfile, format: format)

          outfile.rewind

          expect(outfile.read).to eq(output)
        end
      end
    end

    context 'with text format' do
      let(:format) { :text }
      let(:output) { 'stats' }

      before do
        stub_stats_call(output)
      end

      describe '.stats' do
        it 'returns a text report' do
          expect(described_class.stats(format: format)).to eq(output)
        end
      end

      describe '.dump_stats' do
        it 'writes stats text file' do
          described_class.dump_stats(outfile, format: format)

          outfile.rewind

          expect(outfile.read).to eq(output)
        end
      end
    end

    context 'with unsupported format' do
      let(:format) { 'unsupported' }

      describe '.stats' do
        it 'raises an error' do
          expect do
            described_class.stats(format: format)
          end.to raise_error(/format must be one of/)
        end
      end

      describe '.dump_stats' do
        it 'raises an error' do
          expect do
            described_class.dump_stats(outfile, format: format)
          end.to raise_error(/format must be one of/)
        end
      end
    end
  end

  context 'when jemalloc is not loaded' do
    before do
      expect(current_process).to receive(:find_function).with('malloc_stats_print').and_return(nil)
    end

    describe '.stats' do
      it 'returns empty string' do
        expect(described_class.stats).to be_empty
      end
    end

    describe '.dump_stats' do
      it 'does nothing' do
        described_class.dump_stats(outfile)

        outfile.rewind

        expect(outfile.read).to be_empty
      end
    end
  end

  def stub_stats_call(output, expected_options = '')
    # Stub function pointer to stats call.
    symbol = instance_double(::FFI::DynamicLibrary::Symbol)
    expect(current_process).to receive(:find_function).with('malloc_stats_print').and_return(symbol)

    # Stub actual function call.
    expect(::FFI::Function).to receive(:new)
      .with(:void, [:pointer, :pointer, :string], symbol)
      .and_return(stats_print)
    expect(stats_print).to receive(:call).with(anything, nil, expected_options) do |callback, _, options|
      callback.call(nil, output)
    end
  end
end
