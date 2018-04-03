shared_examples "ChunkedIO shared tests" do
  around(:each, :partial_support) do |example|
    example.run if chunk_stores.first == Gitlab::Ci::Trace::ChunkedFile::ChunkStore::Redis
  end

  describe '#new' do
    context 'when mode is read' do
      let(:mode) { 'rb' }

      it 'raises no exception' do
        expect { described_class.new(job_id, nil, mode) }.not_to raise_error
        expect { described_class.new(job_id, nil, mode) }.not_to raise_error
      end
    end

    context 'when mode is append' do
      let(:mode) { 'a+b' }

      it 'raises an exception' do
        expect { described_class.new(job_id, nil, mode) }.not_to raise_error
        expect { described_class.new(job_id, nil, mode) }.to raise_error('Already opened by another process')
      end

      context 'when closed after open' do
        it 'does not raise an exception' do
          expect { described_class.new(job_id, nil, mode).close }.not_to raise_error
          expect { described_class.new(job_id, nil, mode) }.not_to raise_error
        end
      end
    end

    context 'when mode is write' do
      let(:mode) { 'wb' }

      it 'raises no exception' do
        expect { described_class.new(job_id, nil, mode) }.to raise_error("Mode 'w' is not supported")
      end
    end
  end

  describe 'Permissions', :partial_support do
    before do
      fill_trace_to_chunks(sample_trace_raw)
    end

    context "when mode is 'a+b'" do
      let(:mode) { 'a+b' }

      it 'can write' do
        expect { described_class.new(job_id, nil, mode).write('abc') }
          .not_to raise_error
      end

      it 'can read' do
        expect { described_class.new(job_id, nil, mode).read(10) }
          .not_to raise_error
      end
    end

    context "when mode is 'ab'" do
      let(:mode) { 'ab' }

      it 'can write' do
        expect { described_class.new(job_id, nil, mode).write('abc') }
          .not_to raise_error
      end

      it 'can not read' do
        expect { described_class.new(job_id, nil, mode).read(10) }
          .to raise_error('not opened for reading')
      end
    end

    context "when mode is 'rb'" do
      let(:mode) { 'rb' }

      it 'can not write' do
        expect { described_class.new(job_id, nil, mode).write('abc') }
          .to raise_error('not opened for writing')
      end

      it 'can read' do
        expect { described_class.new(job_id, nil, mode).read(10) }
          .not_to raise_error
      end
    end
  end

  describe '#seek' do
    subject { chunked_io.seek(pos, where) }

    before do
      set_smaller_buffer_size_than(sample_trace_raw.bytesize)
      fill_trace_to_chunks(sample_trace_raw)
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

  describe '#eof?' do
    subject { chunked_io.eof? }

    before do
      set_smaller_buffer_size_than(sample_trace_raw.bytesize)
      fill_trace_to_chunks(sample_trace_raw)
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

  describe '#each_line' do
    let(:string_io) { StringIO.new(sample_trace_raw) }

    context 'when buffer size is smaller than file size' do
      before do
        set_smaller_buffer_size_than(sample_trace_raw.bytesize)
        fill_trace_to_chunks(sample_trace_raw)
      end

      it 'yields lines' do
        expect { |b| described_class.new(job_id, nil, 'rb').each_line(&b) }
          .to yield_successive_args(*string_io.each_line.to_a)
      end
    end

    context 'when buffer size is larger than file size', :partial_support do
      before do
        set_larger_buffer_size_than(sample_trace_raw.bytesize)
        fill_trace_to_chunks(sample_trace_raw)
      end

      it 'calls get_chunk only once' do
        expect(chunk_stores.first).to receive(:open).once.and_call_original

        described_class.new(job_id, nil, 'rb').each_line { |line| }
      end
    end
  end

  describe '#read' do
    subject { described_class.new(job_id, nil, 'rb').read(length) }

    context 'when read the whole size' do
      let(:length) { nil }

      shared_examples 'reads a trace' do
        it do
          is_expected.to eq(sample_trace_raw)
        end
      end

      context 'when buffer size is smaller than file size' do
        before do
          set_smaller_buffer_size_than(sample_trace_raw.bytesize)
          fill_trace_to_chunks(sample_trace_raw)
        end

        it_behaves_like 'reads a trace'
      end

      context 'when buffer size is larger than file size', :partial_support do
        before do
          set_larger_buffer_size_than(sample_trace_raw.bytesize)
          fill_trace_to_chunks(sample_trace_raw)
        end

        it_behaves_like 'reads a trace'
      end

      context 'when buffer size is half of file size' do
        before do
          set_half_buffer_size_of(sample_trace_raw.bytesize)
          fill_trace_to_chunks(sample_trace_raw)
        end

        it_behaves_like 'reads a trace'
      end
    end

    context 'when read only first 100 bytes' do
      let(:length) { 100 }

      context 'when buffer size is smaller than file size' do
        before do
          set_smaller_buffer_size_than(sample_trace_raw.bytesize)
          fill_trace_to_chunks(sample_trace_raw)
        end

        it 'reads a trace' do
          is_expected.to eq(sample_trace_raw[0, length])
        end
      end

      context 'when buffer size is larger than file size', :partial_support do
        before do
          set_larger_buffer_size_than(sample_trace_raw.bytesize)
          fill_trace_to_chunks(sample_trace_raw)
        end

        it 'reads a trace' do
          is_expected.to eq(sample_trace_raw[0, length])
        end
      end
    end

    context 'when tries to read oversize' do
      let(:length) { sample_trace_raw.bytesize + 1000 }

      context 'when buffer size is smaller than file size' do
        before do
          set_smaller_buffer_size_than(sample_trace_raw.bytesize)
          fill_trace_to_chunks(sample_trace_raw)
        end

        it 'reads a trace' do
          is_expected.to eq(sample_trace_raw)
        end
      end

      context 'when buffer size is larger than file size', :partial_support do
        before do
          set_larger_buffer_size_than(sample_trace_raw.bytesize)
          fill_trace_to_chunks(sample_trace_raw)
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
          set_smaller_buffer_size_than(sample_trace_raw.bytesize)
          fill_trace_to_chunks(sample_trace_raw)
        end

        it 'reads a trace' do
          is_expected.to be_empty
        end
      end

      context 'when buffer size is larger than file size', :partial_support do
        before do
          set_larger_buffer_size_than(sample_trace_raw.bytesize)
          fill_trace_to_chunks(sample_trace_raw)
        end

        it 'reads a trace' do
          is_expected.to be_empty
        end
      end
    end
  end

  describe '#readline' do
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
        set_smaller_buffer_size_than(sample_trace_raw.bytesize)
        fill_trace_to_chunks(sample_trace_raw)
      end

      it_behaves_like 'all line matching'
    end

    context 'when buffer size is larger than file size', :partial_support do
      before do
        set_larger_buffer_size_than(sample_trace_raw.bytesize)
        fill_trace_to_chunks(sample_trace_raw)
      end

      it_behaves_like 'all line matching'
    end

    context 'when buffer size is half of file size' do
      before do
        set_half_buffer_size_of(sample_trace_raw.bytesize)
        fill_trace_to_chunks(sample_trace_raw)
      end

      it_behaves_like 'all line matching'
    end

    context 'when pos is at middle of the file' do
      before do
        set_smaller_buffer_size_than(sample_trace_raw.bytesize)
        fill_trace_to_chunks(sample_trace_raw)

        chunked_io.seek(chunked_io.size / 2)
        string_io.seek(string_io.size / 2)
      end

      it 'reads from pos' do
        expect(chunked_io.readline).to eq(string_io.readline)
      end
    end
  end

  describe '#write' do
    subject { chunked_io.write(data) }

    let(:data) { sample_trace_raw }

    context 'when append mode' do
      let(:mode) { 'a+b' }

      context 'when data does not exist' do
        shared_examples 'writes a trace' do
          it do
            is_expected.to eq(data.bytesize)

            described_class.new(job_id, nil, 'rb') do |stream|
              expect(stream.read).to eq(data)
              expect(chunk_stores.inject(0) { |sum, store| sum + store.chunks_count(job_id) })
                .to eq(stream.send(:chunks_count))
              expect(chunk_stores.inject(0) { |sum, store| sum + store.chunks_size(job_id) })
                .to eq(data.bytesize)
            end
          end
        end

        context 'when buffer size is smaller than file size' do
          before do
            set_smaller_buffer_size_than(data.bytesize)
          end

          it_behaves_like 'writes a trace'
        end

        context 'when buffer size is larger than file size', :partial_support do
          before do
            set_larger_buffer_size_than(data.bytesize)
          end

          it_behaves_like 'writes a trace'
        end

        context 'when buffer size is half of file size' do
          before do
            set_half_buffer_size_of(data.bytesize)
          end

          it_behaves_like 'writes a trace'
        end

        context 'when data is nil' do
          let(:data) { nil }

          it 'writes a trace' do
            expect { subject } .to raise_error('Could not write empty data')
          end
        end
      end

      context 'when data already exists', :partial_support do
        let(:exist_data) { 'exist data' }
        let(:total_size) { exist_data.bytesize + data.bytesize }

        shared_examples 'appends a trace' do
          it do
            described_class.new(job_id, nil, 'a+b') do |stream|
              expect(stream.write(data)).to eq(data.bytesize)
            end

            described_class.new(job_id, nil, 'rb') do |stream|
              expect(stream.read).to eq(exist_data + data)
              expect(chunk_stores.inject(0) { |sum, store| sum + store.chunks_count(job_id) })
                .to eq(stream.send(:chunks_count))
              expect(chunk_stores.inject(0) { |sum, store| sum + store.chunks_size(job_id) })
                .to eq(total_size)
            end
          end
        end

        context 'when buffer size is smaller than file size' do
          before do
            set_smaller_buffer_size_than(data.bytesize)
            fill_trace_to_chunks(exist_data)
          end

          it_behaves_like 'appends a trace'
        end

        context 'when buffer size is larger than file size', :partial_support do
          before do
            set_larger_buffer_size_than(data.bytesize)
            fill_trace_to_chunks(exist_data)
          end

          it_behaves_like 'appends a trace'
        end

        context 'when buffer size is half of file size' do
          before do
            set_half_buffer_size_of(data.bytesize)
            fill_trace_to_chunks(exist_data)
          end

          it_behaves_like 'appends a trace'
        end
      end
    end
  end
end
