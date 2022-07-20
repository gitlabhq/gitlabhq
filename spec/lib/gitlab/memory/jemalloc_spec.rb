# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Memory::Jemalloc do
  let(:outdir) { Dir.mktmpdir }

  after do
    FileUtils.rm_f(outdir)
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
          described_class.dump_stats(path: outdir, format: format)

          file = Dir.entries(outdir).find { |e| e.match(/jemalloc_stats\.#{$$}\.\d+\.json$/) }
          expect(file).not_to be_nil
          expect(File.read(File.join(outdir, file))).to eq(output)
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
        shared_examples 'writes stats text file' do |filename_label, filename_pattern|
          it do
            described_class.dump_stats(path: outdir, format: format, filename_label: filename_label)

            file = Dir.entries(outdir).find { |e| e.match(filename_pattern) }
            expect(file).not_to be_nil
            expect(File.read(File.join(outdir, file))).to eq(output)
          end
        end

        context 'when custom filename label is passed' do
          include_examples 'writes stats text file', 'puma_0', /jemalloc_stats\.#{$$}\.puma_0\.\d+\.txt$/
        end

        context 'when custom filename label is not passed' do
          include_examples 'writes stats text file', nil, /jemalloc_stats\.#{$$}\.\d+\.txt$/
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
            described_class.dump_stats(path: outdir, format: format)
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
      it 'returns nil' do
        expect(described_class.stats).to be_nil
      end
    end

    describe '.dump_stats' do
      it 'does nothing' do
        stub_env('LD_PRELOAD', nil)

        described_class.dump_stats(path: outdir)

        expect(Dir.empty?(outdir)).to be(true)
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
