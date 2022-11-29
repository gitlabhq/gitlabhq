# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'

RSpec.describe Gitlab::Memory::Jemalloc do
  let(:outfile) { Tempfile.new }

  after do
    outfile.close
    outfile.unlink
  end

  context 'when jemalloc is loaded' do
    let(:fiddle_func) { instance_double(::Fiddle::Function) }

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
      expect(::Fiddle::Handle).to receive(:sym).and_raise(Fiddle::DLError)
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
    func_pointer = Fiddle::Pointer.new(0xd34db33f)
    expect(::Fiddle::Handle).to receive(:sym).with('malloc_stats_print').and_return(func_pointer)

    # Stub actual function call.
    expect(::Fiddle::Function).to receive(:new)
      .with(func_pointer, anything, anything)
      .and_return(fiddle_func)
    expect(fiddle_func).to receive(:call).with(anything, nil, expected_options) do |callback, _, options|
      callback.call(nil, output)
    end
  end
end
