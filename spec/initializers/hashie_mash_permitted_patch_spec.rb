# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Hashie::Mash#permitted patch' do
  let(:mash) { Hashie::Mash.new }

  before do
    load Rails.root.join('config/initializers/hashie_mash_permitted_patch.rb')
  end

  describe '#respond_to? with :permitted?' do
    it 'returns false' do
      expect(Gitlab::AppLogger).to receive(:info).with(
        { message: 'Hashie::Mash#respond_to?(:permitted?)', caller: instance_of(Array) })

      expect(mash.respond_to?(:permitted?)).to be false
    end
  end

  describe '#permitted' do
    it 'raises ArgumentError' do
      expect(Gitlab::AppLogger).to receive(:info).with(
        { message: 'Hashie::Mash#permitted?', caller: instance_of(Array) })

      expect { mash.permitted? }.to raise_error(ArgumentError)
    end
  end
end
