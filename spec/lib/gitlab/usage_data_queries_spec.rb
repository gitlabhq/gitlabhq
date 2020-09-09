# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataQueries do
  before do
    allow(ActiveRecord::Base.connection).to receive(:transaction_open?).and_return(false)
  end

  describe '.count' do
    it 'returns the raw SQL' do
      expect(described_class.count(User)).to start_with('SELECT COUNT("users"."id") FROM "users"')
    end
  end

  describe '.distinct_count' do
    it 'returns the raw SQL' do
      expect(described_class.distinct_count(Issue, :author_id)).to eq('SELECT COUNT(DISTINCT "issues"."author_id") FROM "issues"')
    end
  end
end
