# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pagination::Keyset::RequestContext do
  let(:request) { double('request', params: params) }

  describe '#page' do
    subject { described_class.new(request).page }

    context 'with only order_by given' do
      let(:params) { { order_by: :id } }

      it 'extracts order_by/sorting information' do
        page = subject

        expect(page.order_by).to eq(id: :desc)
      end
    end

    context 'with order_by and sort given' do
      let(:params) { { order_by: :created_at, sort: :desc } }

      it 'extracts order_by/sorting information and adds tie breaker' do
        page = subject

        expect(page.order_by).to eq(created_at: :desc, id: :desc)
      end
    end

    context 'with no order_by information given' do
      let(:params) { {} }

      it 'defaults to tie breaker' do
        page = subject

        expect(page.order_by).to eq({ id: :desc })
      end
    end

    context 'with per_page params given' do
      let(:params) { { per_page: 10 } }

      it 'extracts per_page information' do
        page = subject

        expect(page.per_page).to eq(params[:per_page])
      end
    end
  end

  describe '#apply_headers' do
    let(:request) { double('request', url: "http://#{Gitlab.config.gitlab.host}/api/v4/projects?foo=bar") }
    let(:params) { { foo: 'bar' } }
    let(:request_context) { double('request context', params: params, request: request) }
    let(:next_page) { double('next page', order_by: { id: :asc }, lower_bounds: { id: 42 }) }

    subject { described_class.new(request_context).apply_headers(next_page) }

    it 'sets Link header with same host/path as the original request' do
      orig_uri = URI.parse(request_context.request.url)

      expect(request_context).to receive(:header).once do |name, header|
        first_link, _ = /<([^>]+)>; rel="next"/.match(header).captures

        uri = URI.parse(first_link)

        expect(name).to eq('Link')
        expect(uri.host).to eq(orig_uri.host)
        expect(uri.path).to eq(orig_uri.path)
      end

      subject
    end

    it 'sets Link header with a link to the next page' do
      orig_uri = URI.parse(request_context.request.url)

      expect(request_context).to receive(:header).once do |name, header|
        first_link, _ = /<([^>]+)>; rel="next"/.match(header).captures

        query = CGI.parse(URI.parse(first_link).query)

        expect(name).to eq('Link')
        expect(query.except('id_after')).to eq(CGI.parse(orig_uri.query).except('id_after'))
        expect(query['id_after']).to eq(['42'])
      end

      subject
    end

    context 'with descending order' do
      let(:next_page) { double('next page', order_by: { id: :desc }, lower_bounds: { id: 42 }) }

      it 'sets Link header with a link to the next page' do
        orig_uri = URI.parse(request_context.request.url)

        expect(request_context).to receive(:header).once do |name, header|
          first_link, _ = /<([^>]+)>; rel="next"/.match(header).captures

          query = CGI.parse(URI.parse(first_link).query)

          expect(name).to eq('Link')
          expect(query.except('id_before')).to eq(CGI.parse(orig_uri.query).except('id_before'))
          expect(query['id_before']).to eq(['42'])
        end

        subject
      end
    end
  end
end
