require 'spec_helper'

describe Gitlab::Proxy do
  describe '.detect_proxy' do
    subject { described_class.detect_proxy }

    context 'without any existing proxies' do
      before do
        allow(described_class).to receive(:env).and_return({})
      end
      it 'returns an empty array' do
        expect(subject).to be_empty
      end
    end

    context 'with existing proxies' do
      before do
        stubbed_env = { 'http_proxy' => 'http://proxy.example.com',
                        'HTTPS_PROXY' => 'https://proxy.example.com',
                        'http_notaproxy' => 'http://example.com' }
        allow(described_class).to receive(:env).and_return(stubbed_env)
      end

      it 'returns a list of existing proxies' do
        aggregate_failures 'list of proxies' do
          expect(subject).to include('http_proxy')
          expect(subject).to include('HTTPS_PROXY')
          expect(subject).not_to include('http_notaproxy')
        end
      end
    end
  end
end
