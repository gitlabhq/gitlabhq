# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActivityPub::ReleasesOutboxSerializer, feature_category: :groups_and_projects do
  let(:decorated) { described_class.new.with_pagination(request, response) }

  let(:project) { build_stubbed(:project, name: 'Fooify', path: 'fooify') }
  let(:releases) { build_stubbed_list(:release, 3, project: project) }

  before do
    allow(releases).to receive_messages(page: releases, per: releases, current_page: 1, total_pages: 1)
    allow(decorated.paginator).to receive(:paginate).and_return(releases)
  end

  context 'when there is a list of objects provided' do
    subject { decorated.represent(releases, url: '/outbox') }

    let(:request) { ActionDispatch::Request.new({ 'QUERY_STRING' => 'page=1' }) }
    let(:response) { ActionDispatch::Response.new }

    it 'is a OrderedCollection document' do
      expect(subject[:type]).to eq 'OrderedCollectionPage'
    end

    it 'serializes the releases' do
      expect(subject[:orderedItems].count).to eq 3
      expect(subject[:orderedItems][0]).to include(:id, :type, :to, :actor, :object)
    end
  end
end
