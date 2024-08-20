# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveVisualReviewBot,
  migration: :gitlab_main, feature_category: :user_profile do
  let(:migration) { described_class.new }
  let(:ghost_user_migrations_table) { table(:ghost_user_migrations) }
  let(:users_table) { table(:users) }

  let!(:visual_review_bot_user) do
    table(:users).create!(id: 2, username: generate(:username), email: 'visualreviewbot@example.com', projects_limit: 0,
      user_type: 3)
  end

  describe '#up' do
    context 'when running the post deployment migration' do
      it 'creates a ghost user migration record' do
        expect { migrate! }.not_to raise_error
        expect(ghost_user_migrations_table.count).to eq(1)
      end
    end

    context 'when running the post deployment migration without a visual review bot user' do
      before do
        visual_review_bot_user.delete
      end

      it 'does not create a ghost user migration record' do
        expect { migrate! }.not_to raise_error
        expect(ghost_user_migrations_table.count).to eq(0)
      end
    end
  end
end
