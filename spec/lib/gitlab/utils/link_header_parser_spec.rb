# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Utils::LinkHeaderParser do
  let(:parser) { described_class.new(header) }

  describe '#parse' do
    subject { parser.parse }

    context 'with a valid header' do
      let(:header) { generate_header(next: 'http://sandbox.org/next') }
      let(:expected) { { next: { uri: URI('http://sandbox.org/next') } } }

      it { is_expected.to eq(expected) }

      context 'with multiple links' do
        let(:header) { generate_header(next: 'http://sandbox.org/next', previous: 'http://sandbox.org/previous') }
        let(:expected) do
          {
            next: { uri: URI('http://sandbox.org/next') },
            previous: { uri: URI('http://sandbox.org/previous') }
          }
        end

        it { is_expected.to eq(expected) }
      end

      context 'with an incomplete uri' do
        let(:header) { '<http://sandbox.org/next; rel="next"' }

        it { is_expected.to eq({}) }
      end

      context 'with no rel' do
        let(:header) { '<http://sandbox.org/next>; direction="next"' }

        it { is_expected.to eq({}) }
      end

      context 'with multiple rel elements' do
        # check https://datatracker.ietf.org/doc/html/rfc5988#section-5.3:
        # occurrences after the first MUST be ignored by parsers
        let(:header) { '<http://sandbox.org/next>; rel="next"; rel="dummy"' }

        it { is_expected.to eq(expected) }
      end

      context 'when the url is too long' do
        let(:header) { "<http://sandbox.org/#{'a' * 500}>; rel=\"next\"" }

        it { is_expected.to eq({}) }
      end
    end

    context 'with nil header' do
      let(:header) { nil }

      it { is_expected.to eq({}) }
    end

    context 'with empty header' do
      let(:header) { '' }

      it { is_expected.to eq({}) }
    end

    def generate_header(links)
      stringified_links = links.map do |rel, url|
        "<#{url}>; rel=\"#{rel}\""
      end
      stringified_links.join(', ')
    end
  end
end
