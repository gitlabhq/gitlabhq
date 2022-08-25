# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ImpersonationAccessTokenSerializer do
  subject(:serializer) { described_class.new }

  describe '#represent' do
    it 'can render a single token' do
      token = create(:personal_access_token)

      expect(serializer.represent(token)).to be_kind_of(Hash)
    end

    it 'can render a collection of tokens' do
      tokens = create_list(:personal_access_token, 2)

      expect(serializer.represent(tokens)).to be_kind_of(Array)
    end
  end
end
