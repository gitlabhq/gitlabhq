# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupAccessTokenSerializer do
  let_it_be(:group) { create(:group) }
  let_it_be(:bot) { create(:user, :project_bot) }

  subject(:serializer) { described_class.new }

  before do
    group.add_developer(bot)
  end

  describe '#represent' do
    it 'can render a single token' do
      token = create(:personal_access_token, user: bot)

      expect(serializer.represent(token, group: group)).to be_kind_of(Hash)
    end

    it 'can render a collection of tokens' do
      tokens = create_list(:personal_access_token, 2, user: bot)

      expect(serializer.represent(tokens, group: group)).to be_kind_of(Array)
    end
  end
end
