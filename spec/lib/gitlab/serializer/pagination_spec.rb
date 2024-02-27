# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Serializer::Pagination do
  let(:request) { double(url: "#{Gitlab.config.gitlab.url}:8080/api/v4/projects?#{query.to_query}", query_parameters: query) }
  let(:query) { {} }
  let(:response) { spy('response') }
  let(:headers) { spy('headers') }
  let(:pagination) { described_class.new(request, response) }

  describe '#paginate' do
    subject { pagination.paginate(resource) }

    context 'when a multiple resources are present in relation' do
      let(:resource) { User.all }
      let(:query) { { page: 1, per_page: 2 } }

      before do
        allow(response).to receive(:headers).and_return(headers)
        create_list(:user, 3)
      end

      it 'correctly paginates the resource' do
        expect(subject.count).to be 2
      end

      it 'appends relevant headers' do
        expect(headers).to receive(:[]=).with('X-Total', '3')
        expect(headers).to receive(:[]=).with('X-Total-Pages', '2')
        expect(headers).to receive(:[]=).with('X-Per-Page', '2')

        subject
      end
    end

    context 'when an invalid resource is about to be paginated' do
      let(:resource) { create(:user) }

      it 'raises error' do
        expect { subject }.to raise_error(
          described_class::InvalidResourceError)
      end
    end

    context 'when paginating via a cursor' do
      let_it_be(:default_page_size) { ::Gitlab::Pagination::Keyset::Page::DEFAULT_PAGE_SIZE }
      let_it_be(:maximum_page_size) { ::Gitlab::Pagination::Keyset::Page::MAXIMUM_PAGE_SIZE }
      let_it_be(:users) { create_list(:user, maximum_page_size) }

      let(:response) { ActionDispatch::TestResponse.new(200, {}, "") }

      context 'when fetching the first page' do
        let(:resource) { User.order(:id).keyset_paginate }

        it 'appends relevant headers', :aggregate_failures do
          subject

          expect(response.headers['Link']).to start_with("<#{Gitlab.config.gitlab.url}/api/v4/projects?cursor=")
          expect(response.headers['X-Next-Page']).to eq(resource.cursor_for_next_page)
          expect(response.headers['X-Page']).to be_nil
          expect(response.headers['X-Page-Type']).to eq('cursor')
          expect(response.headers['X-Per-Page']).to eq(default_page_size)
          expect(response.headers['X-Prev-Page']).to eq(resource.cursor_for_previous_page)
        end

        it 'returns the records' do
          expect(subject).to match_array(User.order(:id).take(default_page_size))
        end
      end

      context 'when fetching a subsequent page' do
        let(:cursor) { User.order(:id).keyset_paginate.cursor_for_next_page }
        let(:resource) { User.order(:id).keyset_paginate(cursor: cursor) }
        let(:query) { { cursor: cursor } }

        it 'appends relevant headers', :aggregate_failures do
          subject

          expect(response.headers['Link']).to start_with("<#{Gitlab.config.gitlab.url}/api/v4/projects?cursor=")
          expect(response.headers['X-Next-Page']).to eq(resource.cursor_for_next_page)
          expect(response.headers['X-Page']).to eql(cursor)
          expect(response.headers['X-Page-Type']).to eq('cursor')
          expect(response.headers['X-Per-Page']).to eq(default_page_size)
          expect(response.headers['X-Prev-Page']).to eq(resource.cursor_for_previous_page)
        end

        it 'returns the records' do
          expect(subject).to match_array(User.order(:id).offset(default_page_size).limit(default_page_size))
        end
      end
    end
  end
end
