require 'spec_helper'

describe Gitlab::Ci::Trace::HttpIO do
  include HttpIOHelpers

  let(:http_io) { described_class.new(url, size) }
  let(:url) { remote_trace_url }
  let(:size) { remote_trace_size }

  describe '#close' do
    subject { http_io.close }

    it { is_expected.to be_nil }
  end

  describe '#binmode' do
    subject { http_io.binmode }

    it { is_expected.to be_nil }
  end

  describe '#binmode?' do
    subject { http_io.binmode? }

    it { is_expected.to be_truthy }
  end

  describe '#path' do
    subject { http_io.path }

    it { is_expected.to be_nil }
  end

  describe '#url' do
    subject { http_io.url }

    it { is_expected.to eq(url) }
  end

  describe '#seek' do
    subject { http_io.seek(pos, where) }

    context 'when moves pos to end of the file' do
      let(:pos) { 0 }
      let(:where) { IO::SEEK_END }

      it { is_expected.to eq(size) }
    end

    context 'when moves pos to middle of the file' do
      let(:pos) { size / 2 }
      let(:where) { IO::SEEK_SET }

      it { is_expected.to eq(size / 2) }
    end

    context 'when moves pos around' do
      it 'matches the result' do
        expect(http_io.seek(0)).to eq(0)
        expect(http_io.seek(100, IO::SEEK_CUR)).to eq(100)
        expect { http_io.seek(size + 1, IO::SEEK_CUR) }.to raise_error('new position is outside of file')
      end
    end
  end

  describe '#eof?' do
    subject { http_io.eof? }

    context 'when current pos is at end of the file' do
      before do
        http_io.seek(size, IO::SEEK_SET)
      end

      it { is_expected.to be_truthy }
    end

    context 'when current pos is not at end of the file' do
      before do
        http_io.seek(0, IO::SEEK_SET)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#each_line' do
    subject { http_io.each_line }

    let(:string_io) { StringIO.new(remote_trace_body) }

    before do
      stub_remote_trace_206
    end

    it 'yields lines' do
      expect { |b| http_io.each_line(&b) }.to yield_successive_args(*string_io.each_line.to_a)
    end

    context 'when buckets on GCS' do
      context 'when BUFFER_SIZE is larger than file size' do
        before do
          stub_remote_trace_200
          set_larger_buffer_size_than(size)
        end

        it 'calls get_chunk only once' do
          expect_any_instance_of(Net::HTTP).to receive(:request).once.and_call_original

          http_io.each_line { |line| }
        end
      end
    end
  end

  describe '#read' do
    subject { http_io.read(length) }

    context 'when there are no network issue' do
      before do
        stub_remote_trace_206
      end

      context 'when read whole size' do
        let(:length) { nil }

        context 'when BUFFER_SIZE is smaller than file size' do
          before do
            set_smaller_buffer_size_than(size)
          end

          it 'reads a trace' do
            is_expected.to eq(remote_trace_body)
          end
        end

        context 'when BUFFER_SIZE is larger than file size' do
          before do
            set_larger_buffer_size_than(size)
          end

          it 'reads a trace' do
            is_expected.to eq(remote_trace_body)
          end
        end
      end

      context 'when read only first 100 bytes' do
        let(:length) { 100 }

        context 'when BUFFER_SIZE is smaller than file size' do
          before do
            set_smaller_buffer_size_than(size)
          end

          it 'reads a trace' do
            is_expected.to eq(remote_trace_body[0, length])
          end
        end

        context 'when BUFFER_SIZE is larger than file size' do
          before do
            set_larger_buffer_size_than(size)
          end

          it 'reads a trace' do
            is_expected.to eq(remote_trace_body[0, length])
          end
        end
      end

      context 'when tries to read oversize' do
        let(:length) { size + 1000 }

        context 'when BUFFER_SIZE is smaller than file size' do
          before do
            set_smaller_buffer_size_than(size)
          end

          it 'reads a trace' do
            is_expected.to eq(remote_trace_body)
          end
        end

        context 'when BUFFER_SIZE is larger than file size' do
          before do
            set_larger_buffer_size_than(size)
          end

          it 'reads a trace' do
            is_expected.to eq(remote_trace_body)
          end
        end
      end

      context 'when tries to read 0 bytes' do
        let(:length) { 0 }

        context 'when BUFFER_SIZE is smaller than file size' do
          before do
            set_smaller_buffer_size_than(size)
          end

          it 'reads a trace' do
            is_expected.to be_empty
          end
        end

        context 'when BUFFER_SIZE is larger than file size' do
          before do
            set_larger_buffer_size_than(size)
          end

          it 'reads a trace' do
            is_expected.to be_empty
          end
        end
      end
    end

    context 'when there is anetwork issue' do
      let(:length) { nil }

      before do
        stub_remote_trace_500
      end

      it 'reads a trace' do
        expect { subject }.to raise_error(Gitlab::Ci::Trace::HttpIO::FailedToGetChunkError)
      end
    end
  end

  describe '#readline' do
    subject { http_io.readline }

    let(:string_io) { StringIO.new(remote_trace_body) }

    before do
      stub_remote_trace_206
    end

    shared_examples 'all line matching' do
      it 'reads a line' do
        (0...remote_trace_body.lines.count).each do
          expect(http_io.readline).to eq(string_io.readline)
        end
      end
    end

    context 'when there is anetwork issue' do
      let(:length) { nil }

      before do
        stub_remote_trace_500
      end

      it 'reads a trace' do
        expect { subject }.to raise_error(Gitlab::Ci::Trace::HttpIO::FailedToGetChunkError)
      end
    end

    context 'when BUFFER_SIZE is smaller than file size' do
      before do
        set_smaller_buffer_size_than(size)
      end

      it_behaves_like 'all line matching'
    end

    context 'when BUFFER_SIZE is larger than file size' do
      before do
        set_larger_buffer_size_than(size)
      end

      it_behaves_like 'all line matching'
    end

    context 'when pos is at middle of the file' do
      before do
        set_smaller_buffer_size_than(size)

        http_io.seek(size / 2)
        string_io.seek(size / 2)
      end

      it 'reads from pos' do
        expect(http_io.readline).to eq(string_io.readline)
      end
    end
  end

  describe '#write' do
    subject { http_io.write(nil) }

    it { expect { subject }.to raise_error(NotImplementedError) }
  end

  describe '#truncate' do
    subject { http_io.truncate(nil) }

    it { expect { subject }.to raise_error(NotImplementedError) }
  end

  describe '#flush' do
    subject { http_io.flush }

    it { expect { subject }.to raise_error(NotImplementedError) }
  end

  describe '#present?' do
    subject { http_io.present? }

    it { is_expected.to be_truthy }
  end
end
