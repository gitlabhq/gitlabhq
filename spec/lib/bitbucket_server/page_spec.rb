# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe BitbucketServer::Page do
  let(:response) { { 'values' => [{ 'description' => 'Test' }], 'isLastPage' => false, 'nextPageStart' => 2 } }

  before do
    # Autoloading hack
    BitbucketServer::Representation::PullRequest.new({})
  end

  describe '#items' do
    it 'returns collection of needed objects' do
      page = described_class.new(response, :pull_request)

      expect(page.items.first).to be_a(BitbucketServer::Representation::PullRequest)
      expect(page.items.count).to eq(1)
    end
  end

  describe '#attrs' do
    it 'returns attributes' do
      page = described_class.new(response, :pull_request)

      expect(page.attrs.keys).to include(:isLastPage, :nextPageStart)
    end
  end

  describe '#next?' do
    it 'returns true' do
      page = described_class.new(response, :pull_request)

      expect(page.next?).to be_truthy
    end

    it 'returns false' do
      response['isLastPage'] = true
      response.delete('nextPageStart')
      page = described_class.new(response, :pull_request)

      expect(page.next?).to be_falsey
    end
  end

  describe '#next' do
    it 'returns next attribute' do
      page = described_class.new(response, :pull_request)

      expect(page.next).to eq(2)
    end
  end
end
