# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Serializer::Pagination do
  let(:request) { double(url: "#{Gitlab.config.gitlab.url}:8080/api/v4/projects?#{query.to_query}", query_parameters: query) }
  let(:response) { spy('response') }
  let(:headers) { spy('headers') }

  before do
    allow(response).to receive(:headers).and_return(headers)
  end

  let(:pagination) { described_class.new(request, response) }

  describe '#paginate' do
    subject { pagination.paginate(resource) }

    let(:resource) { User.all }
    let(:query) { { page: 1, per_page: 2 } }

    context 'when a multiple resources are present in relation' do
      before do
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
  end
end
