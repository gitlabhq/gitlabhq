# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Reports::Security::ScannedResource do
  let(:url) { 'http://example.com:3001/1?foo=bar' }
  let(:request_method) { 'GET' }

  context 'when the URI is not a URI' do
    subject { ::Gitlab::Ci::Reports::Security::ScannedResource.new(url, request_method) }

    it 'raises an error' do
      expect { subject }.to raise_error(ArgumentError)
    end
  end

  context 'when the URL is valid' do
    subject { ::Gitlab::Ci::Reports::Security::ScannedResource.new(URI.parse(url), request_method) }

    it 'sets the URL attributes' do
      expect(subject.request_method).to eq(request_method)
      expect(subject.request_uri.to_s).to eq(url)
      expect(subject.url_scheme).to eq('http')
      expect(subject.url_host).to eq('example.com')
      expect(subject.url_port).to eq(3001)
      expect(subject.url_path).to eq('/1')
      expect(subject.url_query).to eq('foo=bar')
    end
  end
end
