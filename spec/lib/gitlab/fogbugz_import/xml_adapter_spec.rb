# frozen_string_literal: true

require 'spec_helper'

# These specs are copying the requirements laid out by the original adapter
# spec: https://github.com/relatel/ruby-fogbugz/blob/master/spec/adapters/xml/crack_spec.rb
RSpec.describe Gitlab::FogbugzImport::XmlAdapter, feature_category: :importers do
  let(:xml) { nil }

  subject(:parsed_xml) { described_class.parse(xml) }

  context 'when parsing an XML response' do
    let(:xml) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <response>
          <case>
            <ixBug>1234</ixBug>
            <sTitle>Sample Bug</sTitle>
          </case>
        </response>
      XML
    end

    it { is_expected.to eq({ 'case' => { 'ixBug' => '1234', 'sTitle' => 'Sample Bug' } }) }
  end

  context 'when given an HTML response' do
    let(:xml) do
      <<~HTML
        <html lang="en">
          <head><title>Object moved</title></head>
          <body><h2>Object moved to <a href="/new-location">here</a>.</h2></body>
        </html>
      HTML
    end

    it { is_expected.to be_nil }
  end

  context 'when parsing invalid XML' do
    let(:xml) { "hold on, this isn't XML at all!" }

    it { is_expected.to be_nil }
  end

  context 'when the XML body is too large' do
    let(:xml) { instance_double(String, bytesize: described_class::MAX_ALLOWED_BYTES + 1) }

    it 'raises a ResponseTooLargeError' do
      expect { parsed_xml }.to raise_error(described_class::ResponseTooLargeError, /XML exceeds permitted size/)
    end
  end

  context 'when the XML body is too complex' do
    before do
      stub_const("#{described_class}::MAX_ALLOWED_OBJECTS", 3)
    end

    let(:xml) { '<one><two><three><four></four></three></two></one>' }

    it 'raises a ResponseTooLargeError' do
      expect { parsed_xml }.to raise_error(described_class::ResponseTooLargeError, /XML exceeds permitted complexity/)
    end

    context 'when using the standard Nokogiri adapter' do
      it 'does not raise' do
        expect do
          ActiveSupport::XmlMini.with_backend('Nokogiri') do
            Hash.from_xml(xml)['response']
          end
        end.not_to raise_error
      end
    end
  end
end
