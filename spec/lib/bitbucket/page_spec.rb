# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Bitbucket::Page do
  let(:response) { { 'values' => [{ 'username' => 'Ben' }], 'pagelen' => 2, 'next' => '' } }

  before do
    # Autoloading hack
    Bitbucket::Representation::User.new({})
  end

  describe '#items' do
    it 'returns collection of needed objects' do
      page = described_class.new(response, :user)

      expect(page.items.first).to be_a(Bitbucket::Representation::User)
      expect(page.items.count).to eq(1)
    end
  end

  describe '#attrs' do
    it 'returns attributes' do
      page = described_class.new(response, :user)

      expect(page.attrs.keys).to include(:pagelen, :next)
    end
  end

  describe '#next?' do
    it 'returns true' do
      page = described_class.new(response, :user)

      expect(page.next?).to be_truthy
    end

    it 'returns false' do
      response['next'] = nil
      page = described_class.new(response, :user)

      expect(page.next?).to be_falsey
    end
  end

  describe '#next' do
    it 'returns next attribute' do
      page = described_class.new(response, :user)

      expect(page.next).to eq('')
    end
  end
end
