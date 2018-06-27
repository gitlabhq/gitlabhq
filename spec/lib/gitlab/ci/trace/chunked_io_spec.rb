require 'spec_helper'

describe Gitlab::Ci::Trace::ChunkedIO, :clean_gitlab_redis_cache do
  include ChunkedIOHelpers

  set(:build) { create(:ci_build, :running) }
  let(:chunked_io) { described_class.new(build) }

  before do
    stub_feature_flags(ci_enable_live_trace: true)
  end

  context "#initialize" do
    context 'when a chunk exists' do
      before do
        build.trace.set('ABC')
      end

      it { expect(chunked_io.size).to eq(3) }
    end

    context 'when two chunks exist' do
      before do
        stub_buffer_size(4)
        build.trace.set('ABCDEF')
      end

      it { expect(chunked_io.size).to eq(6) }
    end

    context 'when no chunks exists' do
      it { expect(chunked_io.size).to eq(0) }
    end
  end

  context "#seek" do
    subject { chunked_io.seek(pos, where) }

    before do
      build.trace.set(sample_trace_raw)
    end

    context 'when moves pos to end of the file' do
      let(:pos) { 0 }
      let(:where) { IO::SEEK_END }

      it { is_expected.to eq(sample_trace_raw.bytesize) }
    end

    context 'when moves pos to middle of the file' do
      let(:pos) { sample_trace_raw.bytesize / 2 }
      let(:where) { IO::SEEK_SET }

      it { is_expected.to eq(pos) }
    end

    context 'when moves pos around' do
      it 'matches the result' do
        expect(chunked_io.seek(0)).to eq(0)
        expect(chunked_io.seek(100, IO::SEEK_CUR)).to eq(100)
        expect { chunked_io.seek(sample_trace_raw.bytesize + 1, IO::SEEK_CUR) }
          .to raise_error('new position is outside of file')
      end
    end
  end

  context "#eof?" do
    subject { chunked_io.eof? }

    before do
      build.trace.set(sample_trace_raw)
    end

    context 'when current pos is at end of the file' do
      before do
        chunked_io.seek(sample_trace_raw.bytesize, IO::SEEK_SET)
      end

      it { is_expected.to be_truthy }
    end

    context 'when current pos is not at end of the file' do
      before do
        chunked_io.seek(0, IO::SEEK_SET)
      end

      it { is_expected.to be_falsey }
    end
  end

  context "#each_line" do
    let(:string_io) { StringIO.new(sample_trace_raw) }

    context 'when buffer size is smaller than file size' do
      before do
        stub_buffer_size(sample_trace_raw.bytesize / 2)
        build.trace.set(sample_trace_raw)
      end

      it 'yields lines' do
        expect { |b| chunked_io.each_line(&b) }
          .to yield_successive_args(*string_io.each_line.to_a)
      end
    end

    context 'when buffer size is larger than file size' do
      before do
        stub_buffer_size(sample_trace_raw.bytesize * 2)
        build.trace.set(sample_trace_raw)
      end

      it 'calls get_chunk only once' do
        expect_any_instance_of(Gitlab::Ci::Trace::ChunkedIO)
          .to receive(:current_chunk).once.and_call_original

        chunked_io.each_line { |line| }
      end
    end
  end

  context "#read" do
    subject { chunked_io.read(length) }

    context 'when read the whole size' do
      let(:length) { nil }

      context 'when buffer size is smaller than file size' do
        before do
          stub_buffer_size(sample_trace_raw.bytesize / 2)
          build.trace.set(sample_trace_raw)
        end

        it { is_expected.to eq(sample_trace_raw) }
      end

      context 'when buffer size is larger than file size' do
        before do
          stub_buffer_size(sample_trace_raw.bytesize * 2)
          build.trace.set(sample_trace_raw)
        end

        it { is_expected.to eq(sample_trace_raw) }
      end
    end

    context 'when read only first 100 bytes' do
      let(:length) { 100 }

      context 'when buffer size is smaller than file size' do
        before do
          stub_buffer_size(sample_trace_raw.bytesize / 2)
          build.trace.set(sample_trace_raw)
        end

        it 'reads a trace' do
          is_expected.to eq(sample_trace_raw.byteslice(0, length))
        end
      end

      context 'when buffer size is larger than file size' do
        before do
          stub_buffer_size(sample_trace_raw.bytesize * 2)
          build.trace.set(sample_trace_raw)
        end

        it 'reads a trace' do
          is_expected.to eq(sample_trace_raw.byteslice(0, length))
        end
      end
    end

    context 'when tries to read oversize' do
      let(:length) { sample_trace_raw.bytesize + 1000 }

      context 'when buffer size is smaller than file size' do
        before do
          stub_buffer_size(sample_trace_raw.bytesize / 2)
          build.trace.set(sample_trace_raw)
        end

        it 'reads a trace' do
          is_expected.to eq(sample_trace_raw)
        end
      end

      context 'when buffer size is larger than file size' do
        before do
          stub_buffer_size(sample_trace_raw.bytesize * 2)
          build.trace.set(sample_trace_raw)
        end

        it 'reads a trace' do
          is_expected.to eq(sample_trace_raw)
        end
      end
    end

    context 'when tries to read 0 bytes' do
      let(:length) { 0 }

      context 'when buffer size is smaller than file size' do
        before do
          stub_buffer_size(sample_trace_raw.bytesize / 2)
          build.trace.set(sample_trace_raw)
        end

        it 'reads a trace' do
          is_expected.to be_empty
        end
      end

      context 'when buffer size is larger than file size' do
        before do
          stub_buffer_size(sample_trace_raw.bytesize * 2)
          build.trace.set(sample_trace_raw)
        end

        it 'reads a trace' do
          is_expected.to be_empty
        end
      end
    end
  end

  context "#readline" do
    subject { chunked_io.readline }

    let(:string_io) { StringIO.new(sample_trace_raw) }

    shared_examples 'all line matching' do
      it do
        (0...sample_trace_raw.lines.count).each do
          expect(chunked_io.readline).to eq(string_io.readline)
        end
      end
    end

    context 'when buffer size is smaller than file size' do
      before do
        stub_buffer_size(sample_trace_raw.bytesize / 2)
        build.trace.set(sample_trace_raw)
      end

      it_behaves_like 'all line matching'
    end

    context 'when buffer size is larger than file size' do
      before do
        stub_buffer_size(sample_trace_raw.bytesize * 2)
        build.trace.set(sample_trace_raw)
      end

      it_behaves_like 'all line matching'
    end

    context 'when pos is at middle of the file' do
      before do
        stub_buffer_size(sample_trace_raw.bytesize / 2)
        build.trace.set(sample_trace_raw)

        chunked_io.seek(chunked_io.size / 2)
        string_io.seek(string_io.size / 2)
      end

      it 'reads from pos' do
        expect(chunked_io.readline).to eq(string_io.readline)
      end
    end
  end

  context "#write" do
    subject { chunked_io.write(data) }

    let(:data) { sample_trace_raw }

    context 'when data does not exist' do
      shared_examples 'writes a trace' do
        it do
          is_expected.to eq(data.bytesize)

          chunked_io.seek(0, IO::SEEK_SET)
          expect(chunked_io.read).to eq(data)
        end
      end

      context 'when buffer size is smaller than file size' do
        before do
          stub_buffer_size(data.bytesize / 2)
        end

        it_behaves_like 'writes a trace'
      end

      context 'when buffer size is larger than file size' do
        before do
          stub_buffer_size(data.bytesize * 2)
        end

        it_behaves_like 'writes a trace'
      end
    end

    context 'when data already exists' do
      let(:exist_data) { 'exist data' }

      shared_examples 'appends a trace' do
        it do
          chunked_io.seek(0, IO::SEEK_END)
          is_expected.to eq(data.bytesize)

          chunked_io.seek(0, IO::SEEK_SET)
          expect(chunked_io.read).to eq(exist_data + data)
        end
      end

      context 'when buffer size is smaller than file size' do
        before do
          stub_buffer_size(sample_trace_raw.bytesize / 2)
          build.trace.set(exist_data)
        end

        it_behaves_like 'appends a trace'
      end

      context 'when buffer size is larger than file size' do
        before do
          stub_buffer_size(sample_trace_raw.bytesize * 2)
          build.trace.set(exist_data)
        end

        it_behaves_like 'appends a trace'
      end
    end
  end

  context "#truncate" do
    let(:offset) { 10 }

    context 'when data does not exist' do
      shared_examples 'truncates a trace' do
        it do
          chunked_io.truncate(offset)

          chunked_io.seek(0, IO::SEEK_SET)
          expect(chunked_io.read).to eq(sample_trace_raw.byteslice(0, offset))
        end
      end

      context 'when buffer size is smaller than file size' do
        before do
          stub_buffer_size(sample_trace_raw.bytesize / 2)
          build.trace.set(sample_trace_raw)
        end

        it_behaves_like 'truncates a trace'
      end

      context 'when buffer size is larger than file size' do
        before do
          stub_buffer_size(sample_trace_raw.bytesize * 2)
          build.trace.set(sample_trace_raw)
        end

        it_behaves_like 'truncates a trace'
      end
    end
  end

  context "#destroy!" do
    subject { chunked_io.destroy! }

    before do
      build.trace.set(sample_trace_raw)
    end

    it 'deletes' do
      expect { subject }.to change { chunked_io.size }
        .from(sample_trace_raw.bytesize).to(0)

      expect(Ci::BuildTraceChunk.where(build: build).count).to eq(0)
    end
  end
end
