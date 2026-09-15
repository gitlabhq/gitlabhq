# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HttpIO, feature_category: :job_artifacts do
  include HttpIOHelpers

  let(:http_io) { described_class.new(url, size) }

  let(:url) { 'http://object-storage/trace' }
  let(:file_path) { expand_fixture_path('trace/sample_trace') }
  let(:file_body) { File.read(file_path).force_encoding(Encoding::BINARY) }
  let(:size) { File.size(file_path) }

  describe '#close' do
    subject { http_io.close }

    it { is_expected.to be_nil }

    context 'when a persistent connection is open' do
      before do
        stub_remote_url_206(url, file_path)
        set_smaller_buffer_size_than(size)
        http_io.read(1)
      end

      it 'finishes the session', :aggregate_failures do
        session = http_io.send(:http_session)
        expect(session).to be_started

        http_io.close

        expect(session).not_to be_started
        expect(http_io.instance_variable_get(:@http_session)).to be_nil
      end

      context 'when the session has already been torn down' do
        it 'does not raise and resets the session to nil', :aggregate_failures do
          session = http_io.send(:http_session)
          allow(session).to receive(:finish).and_raise(IOError)

          expect { http_io.close }.not_to raise_error
          expect(http_io.instance_variable_get(:@http_session)).to be_nil
        end
      end
    end
  end

  describe 'connection handling' do
    before do
      stub_remote_url_206(url, file_path)
      set_smaller_buffer_size_than(size)
    end

    it 'reuses a single connection configured for keep-alive and explicit timeouts' do
      # Net::HTTP.start ignores option keys that do not name a setter, so a
      # typo would silently fall back to the default. Assert on every option.
      expect(Net::HTTP).to receive(:start).once.with(
        'object-storage', 80,
        hash_including(
          **Gitlab::HTTP::DEFAULT_TIMEOUT_OPTIONS,
          ignore_eof: false,
          keep_alive_timeout: described_class::KEEP_ALIVE_TIMEOUT,
          max_retries: described_class::MAX_RETRIES
        )
      ).and_call_original

      expect(http_io.read).to eq(file_body)
    end

    context 'when the connection fails mid-read' do
      before do
        # This example asserts single-attempt behavior. Flags default to enabled in specs, so
        # disable this one here; the retry path is covered under 'retrying transient failures'.
        stub_feature_flags(http_io_retry_transient_errors: false)
        stub_request(:get, url).to_raise(Errno::ECONNRESET)
      end

      it 'surfaces the error instead of returning a truncated read' do
        expect { http_io.read }.to raise_error(Errno::ECONNRESET)
      end
    end
  end

  describe 'connection lifecycle against a real keep-alive server' do
    let(:server) { HttpIOHelpers::RangeRequestServer.new(file_body) }
    let(:url) { "http://127.0.0.1:#{server.port}/trace" }

    before do
      set_smaller_buffer_size_than(size)
    end

    after do
      server.stop
    end

    it 'reads all chunks over a single connection', :aggregate_failures do
      expect(http_io.read).to eq(file_body)

      expect(server.responses).to be > 1
      expect(server.accepts).to eq(1)
    end

    context 'when the server drops the connection after every response' do
      let(:server) { HttpIOHelpers::RangeRequestServer.new(file_body, drop_connection_after: 1) }

      it 'reconnects transparently and returns the full body', :aggregate_failures do
        expect(http_io.read).to eq(file_body)

        expect(server.responses).to be > 1
        expect(server.accepts).to eq(server.responses)
      end
    end

    context 'when the server fails persistently and then recovers' do
      before do
        # Asserts on Net::HTTP's own single retry, which HttpIO retries would
        # otherwise absorb.
        stub_feature_flags(http_io_retry_transient_errors: false)
      end

      it 'surfaces the error, then a retried read on the same object succeeds', :aggregate_failures do
        server.fail_next_requests(2)

        expect { http_io.read }.to raise_error(described_class::FailedToGetChunkError)

        http_io.seek(0)
        expect(http_io.read).to eq(file_body)

        # initial connection + Net::HTTP internal retry + fresh connection
        # for the successful read
        expect(server.accepts).to eq(3)
      end
    end

    context 'when the connection dies mid-body' do
      it 'discards the partial body, retries transparently and returns correct data', :aggregate_failures do
        server.truncate_next_responses(1)

        expect(http_io.read).to eq(file_body)

        # initial connection + reconnect for the retried chunk
        expect(server.accepts).to eq(2)
      end

      context 'when the truncation persists' do
        before do
          stub_feature_flags(http_io_retry_transient_errors: false)
        end

        it 'surfaces the error, then a retried read on the same object succeeds', :aggregate_failures do
          server.truncate_next_responses(2)

          expect { http_io.read }.to raise_error(described_class::FailedToGetChunkError)

          http_io.seek(0)
          expect(http_io.read).to eq(file_body)

          # initial connection + Net::HTTP internal retry + fresh connection
          # for the successful read
          expect(server.accepts).to eq(3)
        end
      end
    end
  end

  describe 'retrying transient failures', :prometheus do
    before do
      set_smaller_buffer_size_than(size)
      # Stub sleep to avoid real backoff delays. allow_next_instance_of rather
      # than allow(http_io), which would instantiate http_io before inner
      # contexts stub the feature flag that initialize reads.
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:sleep)
      end
    end

    context 'with a transient response code' do
      it 'retries and returns the body' do
        stub_request(:get, url)
          .to_return(status: 503).then
          .to_return { |request| remote_url_response(file_path, request, 206) }

        expect(http_io.read).to eq(file_body)
      end

      it 'gives up once the budget is spent' do
        stub_remote_url_500(url)

        expect { http_io.read }.to raise_error(described_class::FailedToGetChunkError, 'Unexpected response code: 500')
        expect(a_request(:get, url)).to have_been_made.times(described_class::RETRY_BUDGET + 1)
      end

      it 'counts the retry against its reason' do
        counter = instance_double(Prometheus::Client::Counter, increment: nil)
        allow(Gitlab::Metrics).to receive(:counter)
          .with(:gitlab_http_io_chunk_retries_total, anything).and_return(counter)
        stub_request(:get, url)
          .to_return(status: 503).then
          .to_return { |request| remote_url_response(file_path, request, 206) }

        http_io.read

        expect(counter).to have_received(:increment).with(reason: 'http_503').once
      end
    end

    context 'with the backoff delay' do
      let(:base) { described_class::RETRY_BASE_DELAY }

      it 'doubles per retry' do
        stub_remote_url_500(url)
        delays = []
        allow(http_io).to receive(:sleep) { |seconds| delays << seconds }
        # Pin the jitter factor to 1, so the delays are exactly the intended
        # multiples of the base.
        allow(http_io).to receive(:rand).and_return(0.5)

        expect { http_io.read }.to raise_error(described_class::FailedToGetChunkError)
        expect(delays).to eq([base, base * 2, base * 4])
      end
    end

    context 'when the connection keeps dying mid-body' do
      it 'preserves the original EOFError as the cause of the raised error' do
        stub_request(:get, url).to_raise(EOFError)

        expect { http_io.read }.to raise_error(described_class::FailedToGetChunkError) do |error|
          expect(error.cause).to be_a(EOFError)
        end
      end
    end

    context 'with a transport error that persists past the budget' do
      it 'surfaces the original error after the final attempt', :aggregate_failures do
        stub_request(:get, url).to_raise(Errno::ECONNRESET)

        expect { http_io.read }.to raise_error(Errno::ECONNRESET)
        expect(a_request(:get, url)).to have_been_made.times(described_class::RETRY_BUDGET + 1)
      end
    end

    context 'with a response code that will not change on a retry' do
      it 'fails on the first attempt' do
        stub_request(:get, url).to_return(status: 404)

        expect { http_io.read }.to raise_error(described_class::FailedToGetChunkError, 'Unexpected response code: 404')
        expect(a_request(:get, url)).to have_been_made.once
      end
    end

    context 'when the handshake fails while opening the session' do
      # Net::HTTP.start connects outside #transport_request, so its own retry
      # never covers this - the failure reported in the originating incident.
      it 'retries on a fresh session' do
        stub_remote_url_206(url, file_path)
        starts = 0
        allow(Net::HTTP).to receive(:start).and_wrap_original do |original, *args, **kwargs|
          starts += 1
          if starts == 1
            raise OpenSSL::SSL::SSLError, 'SSL_connect returned=6 errno=107 state=SSLv3/TLS write client hello'
          end

          original.call(*args, **kwargs)
        end

        expect(http_io.read).to eq(file_body)
        expect(starts).to eq(2)
      end
    end

    context 'when failures are spread across chunks' do
      let(:buffer_size) { 32.kilobytes }

      before do
        stub_const("Gitlab::HttpIO::BUFFER_SIZE", buffer_size)
      end

      it 'shares one budget across the whole read rather than allowing one per chunk' do
        requests = 0
        stub_request(:get, url).to_return do |request|
          requests += 1
          requests.even? ? { status: 503 } : remote_url_response(file_path, request, 206)
        end

        # Every other request fails, so no single chunk exhausts the budget on
        # its own; the read fails on the failure after the budget is spent.
        expect { http_io.read }.to raise_error(described_class::FailedToGetChunkError)
        expect(requests).to eq((2 * described_class::RETRY_BUDGET) + 2)
      end
    end

    context 'when the flag is disabled' do
      before do
        stub_feature_flags(http_io_retry_transient_errors: false)
      end

      it 'fails on the first attempt' do
        stub_remote_url_500(url)

        expect { http_io.read }.to raise_error(described_class::FailedToGetChunkError)
        expect(a_request(:get, url)).to have_been_made.once
      end
    end

    context 'with a real keep-alive server' do
      let(:server) { HttpIOHelpers::RangeRequestServer.new(file_body) }
      let(:url) { "http://127.0.0.1:#{server.port}/trace" }

      after do
        server.stop
      end

      it 'absorbs a truncation that outlasts Net::HTTP\'s own retry' do
        server.truncate_next_responses(2)

        expect(http_io.read).to eq(file_body)
      end
    end
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

    let(:string_io) { StringIO.new(file_body) }

    before do
      stub_remote_url_206(url, file_path)
    end

    it 'yields lines' do
      expect { |b| http_io.each_line(&b) }.to yield_successive_args(*string_io.each_line.to_a)
    end

    context 'when buckets on GCS' do
      context 'when BUFFER_SIZE is larger than file size' do
        before do
          stub_remote_url_200(url, file_path)
          set_larger_buffer_size_than(size)
        end

        it 'calls get_chunk only once' do
          expect_next_instance_of(Net::HTTP) do |instance|
            expect(instance).to receive(:request).once.and_call_original
          end

          http_io.each_line { |line| }
        end
      end
    end
  end

  describe '#read' do
    subject { http_io.read(length) }

    shared_examples 'reads the body' do
      let(:expected_outbuf) { expected_body || "" }

      it 'reads a trace' do
        is_expected.to eq(expected_body)
      end

      it 'reads with outbuf' do
        buf = +""

        expect(http_io.read(length, buf)).to eq(expected_body)
        expect(buf).to eq(expected_outbuf)
      end
    end

    context 'when there are no network issue' do
      let(:expected_body) { file_body }

      before do
        stub_remote_url_206(url, file_path)
      end

      context 'when read whole size' do
        let(:length) { nil }

        context 'when BUFFER_SIZE is smaller than file size' do
          before do
            set_smaller_buffer_size_than(size)
          end

          it_behaves_like 'reads the body'
        end

        context 'when BUFFER_SIZE is larger than file size' do
          before do
            set_larger_buffer_size_than(size)
          end

          it_behaves_like 'reads the body'
        end
      end

      context 'when read only first 100 bytes' do
        let(:length) { 100 }
        let(:expected_body) { file_body[0, length] }

        context 'when BUFFER_SIZE is smaller than file size' do
          before do
            set_smaller_buffer_size_than(size)
          end

          it_behaves_like 'reads the body'
        end

        context 'when BUFFER_SIZE is larger than file size' do
          before do
            set_larger_buffer_size_than(size)
          end

          it_behaves_like 'reads the body'
        end
      end

      context 'when tries to read oversize' do
        let(:length) { size + 1000 }
        let(:expected_body) { file_body }

        context 'when BUFFER_SIZE is smaller than file size' do
          before do
            set_smaller_buffer_size_than(size)
          end

          it_behaves_like 'reads the body'
        end

        context 'when BUFFER_SIZE is larger than file size' do
          before do
            set_larger_buffer_size_than(size)
          end

          it_behaves_like 'reads the body'
        end
      end

      context 'when tries to read 0 bytes' do
        let(:length) { 0 }
        let(:expected_body) { "" }

        context 'when BUFFER_SIZE is smaller than file size' do
          before do
            set_smaller_buffer_size_than(size)
          end

          it_behaves_like 'reads the body'
        end

        context 'when BUFFER_SIZE is larger than file size' do
          before do
            set_larger_buffer_size_than(size)
          end

          it_behaves_like 'reads the body'
        end
      end
    end

    context 'when current pos is at end of the file' do
      before do
        http_io.seek(size, IO::SEEK_SET)
      end

      it 'returns nil when attempting to read a byte' do
        expect(http_io.read(1)).to be_nil
      end

      it 'returns "" when attempting to read 0 bytes' do
        expect(http_io.read(0)).to eq("")
      end

      it 'returns "" when attempting to read' do
        expect(http_io.read).to eq("")
      end
    end

    context 'when there is a network issue' do
      let(:length) { nil }

      before do
        # This example asserts single-attempt behavior. Flags default to enabled in specs, so
        # disable this one here; the retry path is covered under 'retrying transient failures'.
        stub_feature_flags(http_io_retry_transient_errors: false)
        stub_remote_url_500(url)
      end

      it 'reads a trace' do
        expect { subject }.to raise_error(Gitlab::HttpIO::FailedToGetChunkError)
      end
    end
  end

  describe 'chunk caching' do
    # The fixture spans several chunks, and no read step lands on a chunk
    # boundary (192394 % 4096 != 0), so every boundary is crossed mid-step.
    # That is the ordinary case: trace sizes are arbitrary.
    let(:buffer_size) { 32.kilobytes }
    let(:step) { 4.kilobytes }
    let(:chunk_count) { (size.to_f / buffer_size).ceil }
    let(:boundaries) { chunk_count - 1 }

    before do
      stub_remote_url_206(url, file_path)
      stub_const("Gitlab::HttpIO::BUFFER_SIZE", buffer_size)
    end

    # Mirrors Gitlab::Ci::Trace::Stream#read_backward, the caller this cache
    # exists for: walk back to the start of the file in steps smaller than a
    # chunk, re-seeking to the start of each step afterwards.
    def read_backward(io)
      io.seek(0, IO::SEEK_END)
      out = []

      until io.pos == 0
        cur = io.pos
        start = [cur - step, 0].max

        io.seek(start)
        out.unshift(io.read(cur - start))
        io.seek(start)
      end

      out.join
    end

    it 'requests each chunk once', :aggregate_failures do
      expect(read_backward(http_io)).to eq(file_body)

      expect(a_request(:get, url)).to have_been_made.times(chunk_count)
    end

    it 'leaves a forward read unaffected' do
      expect(http_io.read).to eq(file_body)

      expect(a_request(:get, url)).to have_been_made.times(chunk_count)
    end
  end

  describe '#readline' do
    subject { http_io.readline }

    let(:string_io) { StringIO.new(file_body) }

    before do
      stub_remote_url_206(url, file_path)
    end

    shared_examples 'all line matching' do
      it 'reads a line' do
        (0...file_body.lines.count).each do
          expect(http_io.readline).to eq(string_io.readline)
        end
      end
    end

    context 'when there is anetwork issue' do
      let(:length) { nil }

      before do
        # This example asserts single-attempt behavior. Flags default to enabled in specs, so
        # disable this one here; the retry path is covered under 'retrying transient failures'.
        stub_feature_flags(http_io_retry_transient_errors: false)
        stub_remote_url_500(url)
      end

      it 'reads a trace' do
        expect { subject }.to raise_error(Gitlab::HttpIO::FailedToGetChunkError, 'Unexpected response code: 500')
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

  describe '#send' do
    subject(:send) { http_io.send(:request) }

    it 'does not set the "accept-encoding" header' do
      expect(send['accept-encoding']).to be_nil
    end
  end
end
