# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Loaders::BatchModelLoader do
  describe '#find' do
    let_it_be(:issue) { create(:issue) }
    let_it_be(:other_user) { create(:user) }
    let_it_be(:user) { create(:user) }

    it 'finds a model by id' do
      issue_result = described_class.new(Issue, issue.id).find
      user_result = described_class.new(User, user.id).find

      expect(issue_result.sync).to eq(issue)
      expect(user_result.sync).to eq(user)
    end

    it 'only queries once per model' do
      expect do
        [described_class.new(User, other_user.id).find,
         described_class.new(User, user.id).find,
         described_class.new(Issue, issue.id).find].map(&:sync)
      end.not_to exceed_query_limit(2)
    end

    it 'does not force values unnecessarily' do
      expect do
        a = described_class.new(User, user.id).find
        b = described_class.new(Issue, issue.id).find

        b.sync

        c = described_class.new(User, other_user.id).find

        a.sync
        c.sync
      end.not_to exceed_query_limit(2)
    end
  end
end
