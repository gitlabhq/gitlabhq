# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Audit::UnauthenticatedAuthor do
  describe '#initialize' do
    it 'sets correct attributes' do
      expect(described_class.new(name: 'Peppa Pig'))
        .to have_attributes(id: -1, name: 'Peppa Pig')
    end

    it 'sets default name when it is not provided' do
      expect(described_class.new)
        .to have_attributes(id: -1, name: 'An unauthenticated user')
    end

    describe '#impersonated?' do
      it 'returns false' do
        expect(described_class.new.impersonated?).to be(false)
      end
    end
  end
end
