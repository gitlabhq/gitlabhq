# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActivityPub::ActivityStreamsSerializer, feature_category: :integrations do
  let(:implementer_class) do
    Class.new(described_class) do
      include WithPagination
    end
  end

  let(:entity_class) do
    Class.new(Grape::Entity) do
      expose :id do |*|
        'https://example.com/unique/url'
      end

      expose :type do |*|
        'Person'
      end

      expose :name do |*|
        'Alice'
      end
    end
  end

  shared_examples_for 'ActivityStreams document' do
    it 'belongs to the ActivityStreams namespace' do
      expect(subject['@context']).to eq 'https://www.w3.org/ns/activitystreams'
    end

    it 'has a unique identifier' do
      expect(subject).to have_key 'id'
    end

    it 'has a type' do
      expect(subject).to have_key 'type'
    end
  end

  before do
    implementer_class.entity entity_class
  end

  context 'when the serializer is not paginated' do
    let(:resource) { build_stubbed(:release) }
    let(:outbox_url) { 'https://example.com/unique/url/outbox' }

    context 'with a valid represented entity' do
      subject { implementer_class.new.represent(resource, outbox: outbox_url) }

      it_behaves_like 'ActivityStreams document'

      it 'exposes an outbox' do
        expect(subject['outbox']).to eq 'https://example.com/unique/url/outbox'
      end

      it 'includes serialized data' do
        expect(subject['name']).to eq 'Alice'
      end
    end

    context 'when the represented entity provides no identifier' do
      subject { implementer_class.new.represent(resource, outbox: outbox_url) }

      before do
        allow(entity_class).to receive(:represent).and_return({ type: 'Person' })
      end

      it 'raises an exception' do
        expect { subject }.to raise_error(ActivityPub::ActivityStreamsSerializer::MissingIdentifierError)
      end
    end

    context 'when the represented entity provides no type' do
      subject { implementer_class.new.represent(resource, outbox: outbox_url) }

      before do
        allow(entity_class).to receive(:represent).and_return({ id: 'https://example.com/unique/url' })
      end

      it 'raises an exception' do
        expect { subject }.to raise_error(ActivityPub::ActivityStreamsSerializer::MissingTypeError)
      end
    end

    context 'when the caller provides no outbox parameter' do
      subject { implementer_class.new.represent(resource) }

      it 'raises an exception' do
        expect { subject }.to raise_error(ActivityPub::ActivityStreamsSerializer::MissingOutboxError)
      end
    end
  end

  context 'when the serializer is paginated' do
    let(:resources) { build_stubbed_list(:release, 3) }
    let(:request) { ActionDispatch::Request.new(request_data) }
    let(:response) { ActionDispatch::Response.new }
    let(:url) { 'https://example.com/resource/url' }
    let(:decorated) { implementer_class.new.with_pagination(request, response) }

    before do
      allow(resources).to receive(:page).and_return(resources)
      allow(resources).to receive(:per).and_return(resources)
      allow(resources).to receive(:current_page).and_return(2)
      allow(resources).to receive(:total_pages).and_return(3)
      allow(resources).to receive(:total_count).and_return(10)
      allow(decorated.paginator).to receive(:paginate).and_return(resources)
    end

    context 'when no page parameter is provided' do
      subject { decorated.represent(resources) }

      let(:request_data) do
        { "rack.url_scheme" => "https", "HTTP_HOST" => "example.com", "PATH_INFO" => '/resource/url' }
      end

      it_behaves_like 'ActivityStreams document'

      it 'is an index document for the pagination' do
        expect(subject['type']).to eq 'OrderedCollection'
      end

      it 'contains the total amount of items' do
        expect(subject['totalItems']).to eq 10
      end

      it 'contains links to first and last page' do
        expect(subject['first']).to eq "#{url}?page=1"
        expect(subject['last']).to eq "#{url}?page=3"
      end
    end

    context 'when a page parameter is provided' do
      subject { decorated.represent(resources) }

      let(:request_data) do
        { 'rack.url_scheme' => 'https', 'HTTP_HOST' => 'example.com', 'PATH_INFO' => '/resource/url',
          'QUERY_STRING' => 'page=2&per_page=1' }
      end

      it_behaves_like 'ActivityStreams document'

      it 'is a page document' do
        expect(subject['type']).to eq 'OrderedCollectionPage'
      end

      it 'contains navigation links' do
        expect(subject['prev']).to be_present
        expect(subject['next']).to be_present
        expect(subject['partOf']).to be_present
      end
    end
  end
end
