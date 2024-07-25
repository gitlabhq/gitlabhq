# frozen_string_literal: true

# require 'fast_spec_helper' -- this no longer runs under fast_spec_helper
require 'spec_helper'

RSpec.describe Gitlab::Pagination::OffsetHeaderBuilder do
  let(:request) { double(url: 'http://localhost') }
  let(:request_context) { double(header: nil, params: { per_page: 5 }, request: request) }

  subject do
    described_class.new(
      request_context: request_context, per_page: 5, page: 2,
      next_page: 3, prev_page: 1, total: 10, total_pages: 3
    )
  end

  describe '#execute' do
    let(:basic_links) do
      [
        %(<http://localhost?page=1&per_page=5>; rel="prev"),
        %(<http://localhost?page=3&per_page=5>; rel="next"),
        %(<http://localhost?page=1&per_page=5>; rel="first")
      ].join(', ')
    end

    let(:last_link) do
      %(, <http://localhost?page=3&per_page=5>; rel="last")
    end

    def expect_basic_headers
      expect(request_context).to receive(:header).with('X-Per-Page', '5')
      expect(request_context).to receive(:header).with('X-Page', '2')
      expect(request_context).to receive(:header).with('X-Next-Page', '3')
      expect(request_context).to receive(:header).with('X-Prev-Page', '1')
      expect(request_context).to receive(:header).with('Link', basic_links + last_link)
    end

    it 'sets headers to request context' do
      expect_basic_headers
      expect(request_context).to receive(:header).with('X-Total', '10')
      expect(request_context).to receive(:header).with('X-Total-Pages', '3')

      subject.execute
    end

    context 'exclude total headers' do
      it 'does not set total headers to request context' do
        expect_basic_headers
        expect(request_context).not_to receive(:header)

        subject.execute(exclude_total_headers: true)
      end
    end

    context 'pass data without counts' do
      let(:last_link) { '' }

      it 'does not set total headers to request context' do
        expect_basic_headers
        expect(request_context).not_to receive(:header)

        subject.execute(data_without_counts: true)
      end
    end
  end
end
