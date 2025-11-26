# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Pagination::Keyset::CursorBasedRequestContext, feature_category: :database do
  let(:params) { { per_page: 2, cursor: 'eyJuYW1lIjoiR2l0TGFiIEluc3RhbmNlIiwiaWQiOiI1MiIsIl9rZCI6Im4ifQ==', order_by: :name, sort: :asc } }
  let(:request) { double('request', url: 'http://localhost') }
  let(:request_context) { double('request_context', header: nil, params: params, request: request) }

  describe '#per_page' do
    subject(:per_page) { described_class.new(request_context).per_page }

    it { is_expected.to eq 2 }
  end

  describe '#cursor' do
    subject(:cursor) { described_class.new(request_context).cursor }

    it { is_expected.to eq 'eyJuYW1lIjoiR2l0TGFiIEluc3RhbmNlIiwiaWQiOiI1MiIsIl9rZCI6Im4ifQ==' }
  end

  describe '#order_by' do
    subject(:order_by) { described_class.new(request_context).order_by }

    it { is_expected.to eq({ name: :asc }) }
  end

  describe '#apply_headers' do
    let(:request) { double('request', url: "http://#{Gitlab.config.gitlab.host}/api/v4/projects?per_page=3") }
    let(:params) { { per_page: 3 } }
    let(:request_context) { double('request_context', header: nil, params: params, request: request) }
    let(:orig_uri) { URI.parse(request_context.request.url) }

    subject(:apply_headers) { described_class.new(request_context).apply_headers(cursor_for_next_page, cursor_for_previous_page) }

    shared_examples 'sets Link header' do
      it 'sets Link header with same host/path as the original request' do
        expect(request_context).to receive(:header).once.with('X-NEXT-CURSOR', anything) if cursor_for_next_page
        expect(request_context).to receive(:header).once.with('X-PREV-CURSOR', anything) if cursor_for_previous_page

        expect(request_context).to receive(:header).once do |name, header|
          first_link, _ = /<([^>]+)>; rel="next"/.match(header).captures

          uri = URI.parse(first_link)

          expect(name).to eq('Link')
          expect(uri.host).to eq(orig_uri.host)
          expect(uri.path).to eq(orig_uri.path)
        end

        apply_headers
      end

      it 'sets Link header with a cursor to the next page' do
        expect(request_context).to receive(:header).once.with('X-NEXT-CURSOR', anything) if cursor_for_next_page
        expect(request_context).to receive(:header).once.with('X-PREV-CURSOR', anything) if cursor_for_previous_page

        expect(request_context).to receive(:header).once do |name, header|
          first_link, _ = /<([^>]+)>; rel="next"/.match(header).captures

          query = CGI.parse(URI.parse(first_link).query)

          expect(name).to eq('Link')
          expect(query.except('cursor')).to eq(CGI.parse(orig_uri.query).except('cursor'))
          expect(query['cursor']).to eq([cursor_for_next_page])
        end

        apply_headers
      end
    end

    context 'on the first page' do
      let(:cursor_for_next_page) { 'eyJuYW1lIjoiSDVicCIsImlkIjoiMjgiLCJfa2QiOiJuIn0=' }
      let(:cursor_for_previous_page) { nil }

      it_behaves_like 'sets Link header'

      it 'sets X-NEXT-CURSOR header with a cursor to the next page' do
        expect(request_context).to receive(:header).once.with('X-NEXT-CURSOR', cursor_for_next_page)
        expect(request_context).to receive(:header).once.with('Link', anything)

        apply_headers
      end

      it 'does not set X-PREV-CURSOR header' do
        expect(request_context).not_to receive(:header).with('X-PREV-CURSOR', anything)

        apply_headers
      end
    end

    context 'on the last page' do
      let(:cursor_for_next_page) { nil }
      let(:cursor_for_previous_page) { 'eyJuYW1lIjoiSDVicCIsImlkIjoiMjgiLCJfa2QiOiJuIn0=' }

      it 'does not set Link header' do
        expect(request_context).not_to receive(:header).with('Link', anything)

        apply_headers
      end

      it 'does not set X-NEXT-CURSOR cursor header' do
        expect(request_context).not_to receive(:header).with('X-NEXT-CURSOR', anything)

        apply_headers
      end

      it 'sets X-PREV-CURSOR header with a cursor to the previous page' do
        expect(request_context).to receive(:header).once.with('X-PREV-CURSOR', cursor_for_previous_page)

        apply_headers
      end
    end

    context 'on the middle page' do
      let(:cursor_for_next_page) { 'eyJuYW1lIjoiSTZxYyIsImlkIjoiMjkiLCJfa2QiOiJuIn0=' }
      let(:cursor_for_previous_page) { 'eyJuYW1lIjoiSDVicCIsImlkIjoiMjgiLCJfa2QiOiJuIn0=' }

      it_behaves_like 'sets Link header'

      it 'sets X-PREV-CURSOR and X-NEXT-CURSOR headers with corresponding cursors' do
        expect(request_context).to receive(:header).once.with('X-PREV-CURSOR', cursor_for_previous_page)
        expect(request_context).to receive(:header).once.with('X-NEXT-CURSOR', cursor_for_next_page)
        expect(request_context).to receive(:header).once.with('Link', anything)

        apply_headers
      end
    end

    context 'when cursors are nil' do
      let(:cursor_for_next_page) { nil }
      let(:cursor_for_previous_page) { nil }

      it 'does not set Link, X-PREV-CURSOR or X-NEXT-CURSOR headers' do
        expect(request_context).not_to receive(:header).with('X-PREV-CURSOR', anything)
        expect(request_context).not_to receive(:header).with('X-NEXT-CURSOR', anything)
        expect(request_context).not_to receive(:header).with('Link', anything)

        apply_headers
      end
    end
  end
end
