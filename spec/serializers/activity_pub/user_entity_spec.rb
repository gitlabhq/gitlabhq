# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActivityPub::UserEntity, feature_category: :user_profile do
  let(:user) { build_stubbed(:user, name: 'Alice', username: 'alice') }
  let(:entity) { described_class.new(user) }

  context 'as json' do
    subject { entity.as_json }

    it 'has releases page as id' do
      expect(subject[:id]).to match(%r{/alice$})
    end

    it 'is a Person actor' do
      expect(subject[:type]).to eq 'Person'
    end

    it 'provides project name' do
      expect(subject[:name]).to eq 'Alice'
    end

    it 'provides an url for web content' do
      expect(subject[:url]).to match(%r{/alice$})
    end
  end
end
