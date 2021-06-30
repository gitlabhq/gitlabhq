# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HTTP do
  include StubRequests

  let(:default_options) { described_class::DEFAULT_TIMEOUT_OPTIONS }

  context 'when allow_local_requests' do
    it 'sends the request to the correct URI' do
      stub_full_request('https://example.org:8080', ip_address: '8.8.8.8').to_return(status: 200)

      described_class.get('https://example.org:8080', allow_local_requests: false)

      expect(WebMock).to have_requested(:get, 'https://8.8.8.8:8080').once
    end
  end

  context 'when not allow_local_requests' do
    it 'sends the request to the correct URI' do
      stub_full_request('https://example.org:8080')

      described_class.get('https://example.org:8080', allow_local_requests: true)

      expect(WebMock).to have_requested(:get, 'https://8.8.8.9:8080').once
    end
  end

  context 'when reading the response is too slow' do
    before do
      stub_const("#{described_class}::DEFAULT_READ_TOTAL_TIMEOUT", 0.001.seconds)

      WebMock.stub_request(:post, /.*/).to_return do |request|
        sleep 0.002.seconds
        { body: 'I\m slow', status: 200 }
      end
    end

    let(:options) { {} }

    subject(:request_slow_responder) { described_class.post('http://example.org', **options) }

    specify do
      expect { request_slow_responder }.not_to raise_error
    end

    context 'with use_read_total_timeout option' do
      let(:options) { { use_read_total_timeout: true } }

      it 'raises a timeout error' do
        expect { request_slow_responder }.to raise_error(Gitlab::HTTP::ReadTotalTimeout, /Request timed out after ?([0-9]*[.])?[0-9]+ seconds/)
      end

      context 'and timeout option' do
        let(:options) { { use_read_total_timeout: true, timeout: 10.seconds } }

        it 'overrides the default timeout when timeout option is present' do
          expect { request_slow_responder }.not_to raise_error
        end
      end
    end
  end

  it 'calls a block' do
    WebMock.stub_request(:post, /.*/)

    expect { |b| described_class.post('http://example.org', &b) }.to yield_with_args
  end

  describe 'allow_local_requests_from_web_hooks_and_services is' do
    before do
      WebMock.stub_request(:get, /.*/).to_return(status: 200, body: 'Success')
    end

    context 'disabled' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:allow_local_requests_from_web_hooks_and_services?).and_return(false)
      end

      it 'deny requests to localhost' do
        expect { described_class.get('http://localhost:3003') }.to raise_error(Gitlab::HTTP::BlockedUrlError)
      end

      it 'deny requests to private network' do
        expect { described_class.get('http://192.168.1.2:3003') }.to raise_error(Gitlab::HTTP::BlockedUrlError)
      end

      context 'if allow_local_requests set to true' do
        it 'override the global value and allow requests to localhost or private network' do
          stub_full_request('http://localhost:3003')

          expect { described_class.get('http://localhost:3003', allow_local_requests: true) }.not_to raise_error
        end
      end
    end

    context 'enabled' do
      before do
        allow(Gitlab::CurrentSettings).to receive(:allow_local_requests_from_web_hooks_and_services?).and_return(true)
      end

      it 'allow requests to localhost' do
        stub_full_request('http://localhost:3003')

        expect { described_class.get('http://localhost:3003') }.not_to raise_error
      end

      it 'allow requests to private network' do
        expect { described_class.get('http://192.168.1.2:3003') }.not_to raise_error
      end

      context 'if allow_local_requests set to false' do
        it 'override the global value and ban requests to localhost or private network' do
          expect { described_class.get('http://localhost:3003', allow_local_requests: false) }.to raise_error(Gitlab::HTTP::BlockedUrlError)
        end
      end
    end
  end

  describe 'handle redirect loops' do
    before do
      stub_full_request("http://example.org", method: :any).to_raise(HTTParty::RedirectionTooDeep.new("Redirection Too Deep"))
    end

    it 'handles GET requests' do
      expect { described_class.get('http://example.org') }.to raise_error(Gitlab::HTTP::RedirectionTooDeep)
    end

    it 'handles POST requests' do
      expect { described_class.post('http://example.org') }.to raise_error(Gitlab::HTTP::RedirectionTooDeep)
    end

    it 'handles PUT requests' do
      expect { described_class.put('http://example.org') }.to raise_error(Gitlab::HTTP::RedirectionTooDeep)
    end

    it 'handles DELETE requests' do
      expect { described_class.delete('http://example.org') }.to raise_error(Gitlab::HTTP::RedirectionTooDeep)
    end

    it 'handles HEAD requests' do
      expect { described_class.head('http://example.org') }.to raise_error(Gitlab::HTTP::RedirectionTooDeep)
    end
  end

  describe 'setting default timeouts' do
    before do
      stub_full_request('http://example.org', method: :any)
    end

    context 'when no timeouts are set' do
      it 'sets default open and read and write timeouts' do
        expect(described_class).to receive(:httparty_perform_request).with(
          Net::HTTP::Get, 'http://example.org', default_options
        ).and_call_original

        described_class.get('http://example.org')
      end
    end

    context 'when :timeout is set' do
      it 'does not set any default timeouts' do
        expect(described_class).to receive(:httparty_perform_request).with(
          Net::HTTP::Get, 'http://example.org', timeout: 1
        ).and_call_original

        described_class.get('http://example.org', timeout: 1)
      end
    end

    context 'when :open_timeout is set' do
      it 'only sets default read and write timeout' do
        expect(described_class).to receive(:httparty_perform_request).with(
          Net::HTTP::Get, 'http://example.org', default_options.merge(open_timeout: 1)
        ).and_call_original

        described_class.get('http://example.org', open_timeout: 1)
      end
    end

    context 'when :read_timeout is set' do
      it 'only sets default open and write timeout' do
        expect(described_class).to receive(:httparty_perform_request).with(
          Net::HTTP::Get, 'http://example.org', default_options.merge(read_timeout: 1)
        ).and_call_original

        described_class.get('http://example.org', read_timeout: 1)
      end
    end

    context 'when :write_timeout is set' do
      it 'only sets default open and read timeout' do
        expect(described_class).to receive(:httparty_perform_request).with(
          Net::HTTP::Put, 'http://example.org', default_options.merge(write_timeout: 1)
        ).and_call_original

        described_class.put('http://example.org', write_timeout: 1)
      end
    end
  end

  describe '.try_get' do
    let(:path) { 'http://example.org' }

    let(:extra_log_info_proc) do
      proc do |error, url, options|
        { klass: error.class, url: url, options: options }
      end
    end

    let(:request_options) do
      default_options.merge({
        verify: false,
        basic_auth: { username: 'user', password: 'pass' }
      })
    end

    described_class::HTTP_ERRORS.each do |exception_class|
      context "with #{exception_class}" do
        let(:klass) { exception_class }

        context 'with path' do
          before do
            expect(described_class).to receive(:httparty_perform_request)
              .with(Net::HTTP::Get, path, default_options)
              .and_raise(klass)
          end

          it 'handles requests without extra_log_info' do
            expect(Gitlab::ErrorTracking)
              .to receive(:log_exception)
              .with(instance_of(klass), {})

            expect(described_class.try_get(path)).to be_nil
          end

          it 'handles requests with extra_log_info as hash' do
            expect(Gitlab::ErrorTracking)
              .to receive(:log_exception)
              .with(instance_of(klass), { a: :b })

            expect(described_class.try_get(path, extra_log_info: { a: :b })).to be_nil
          end

          it 'handles requests with extra_log_info as proc' do
            expect(Gitlab::ErrorTracking)
              .to receive(:log_exception)
              .with(instance_of(klass), { url: path, klass: klass, options: {} })

            expect(described_class.try_get(path, extra_log_info: extra_log_info_proc)).to be_nil
          end
        end

        context 'with path and options' do
          before do
            expect(described_class).to receive(:httparty_perform_request)
              .with(Net::HTTP::Get, path, request_options)
              .and_raise(klass)
          end

          it 'handles requests without extra_log_info' do
            expect(Gitlab::ErrorTracking)
              .to receive(:log_exception)
              .with(instance_of(klass), {})

            expect(described_class.try_get(path, request_options)).to be_nil
          end

          it 'handles requests with extra_log_info as hash' do
            expect(Gitlab::ErrorTracking)
              .to receive(:log_exception)
              .with(instance_of(klass), { a: :b })

            expect(described_class.try_get(path, **request_options, extra_log_info: { a: :b })).to be_nil
          end

          it 'handles requests with extra_log_info as proc' do
            expect(Gitlab::ErrorTracking)
              .to receive(:log_exception)
              .with(instance_of(klass), { klass: klass, url: path, options: request_options })

            expect(described_class.try_get(path, **request_options, extra_log_info: extra_log_info_proc)).to be_nil
          end
        end

        context 'with path, options, and block' do
          let(:block) do
            proc {}
          end

          before do
            expect(described_class).to receive(:httparty_perform_request)
              .with(Net::HTTP::Get, path, request_options, &block)
              .and_raise(klass)
          end

          it 'handles requests without extra_log_info' do
            expect(Gitlab::ErrorTracking)
              .to receive(:log_exception)
              .with(instance_of(klass), {})

            expect(described_class.try_get(path, request_options, &block)).to be_nil
          end

          it 'handles requests with extra_log_info as hash' do
            expect(Gitlab::ErrorTracking)
              .to receive(:log_exception)
              .with(instance_of(klass), { a: :b })

            expect(described_class.try_get(path, **request_options, extra_log_info: { a: :b }, &block)).to be_nil
          end

          it 'handles requests with extra_log_info as proc' do
            expect(Gitlab::ErrorTracking)
              .to receive(:log_exception)
              .with(instance_of(klass), { klass: klass, url: path, options: request_options })

            expect(described_class.try_get(path, **request_options, extra_log_info: extra_log_info_proc, &block)).to be_nil
          end
        end
      end
    end
  end
end
