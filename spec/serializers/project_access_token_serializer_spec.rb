# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectAccessTokenSerializer do
  let_it_be(:project) { create(:project) }
  let_it_be(:bot) { create(:user, :project_bot, developer_of: project) }

  subject(:serializer) { described_class.new }

  describe '#represent' do
    it 'can render a single token' do
      token = create(:personal_access_token, user: bot)

      expect(serializer.represent(token, project: project)).to be_kind_of(Hash)
    end

    it 'can render a collection of tokens' do
      tokens = create_list(:personal_access_token, 2, user: bot)

      expect(serializer.represent(tokens, project: project)).to be_kind_of(Array)
    end
  end
end
