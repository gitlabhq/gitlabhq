# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateUsersBioToUserDetails, :migration, schema: 20200323074147 do
  let(:users) { table(:users) }

  let(:user_details) do
    klass = table(:user_details)
    klass.primary_key = :user_id
    klass
  end

  let!(:user_needs_migration) { users.create!(name: 'user1', email: 'test1@test.com', projects_limit: 1, bio: 'bio') }
  let!(:user_needs_no_migration) { users.create!(name: 'user2', email: 'test2@test.com', projects_limit: 1) }
  let!(:user_also_needs_no_migration) { users.create!(name: 'user3', email: 'test3@test.com', projects_limit: 1, bio: '') }
  let!(:user_with_long_bio) { users.create!(name: 'user4', email: 'test4@test.com', projects_limit: 1, bio: 'a' * 256) } # 255 is the max

  let!(:user_already_has_details) { users.create!(name: 'user5', email: 'test5@test.com', projects_limit: 1, bio: 'my bio') }
  let!(:existing_user_details) { user_details.find_or_create_by!(user_id: user_already_has_details.id).update!(bio: 'my bio') }

  # unlikely scenario since we have triggers
  let!(:user_has_different_details) { users.create!(name: 'user6', email: 'test6@test.com', projects_limit: 1, bio: 'different') }
  let!(:different_existing_user_details) { user_details.find_or_create_by!(user_id: user_has_different_details.id).update!(bio: 'bio') }

  let(:user_ids) do
    [
      user_needs_migration,
      user_needs_no_migration,
      user_also_needs_no_migration,
      user_with_long_bio,
      user_already_has_details,
      user_has_different_details
    ].map(&:id)
  end

  subject { described_class.new.perform(user_ids.min, user_ids.max) }

  it 'migrates all relevant records' do
    subject

    all_user_details = user_details.all
    expect(all_user_details.size).to eq(4)
  end

  it 'migrates `bio`' do
    subject

    user_detail = user_details.find_by!(user_id: user_needs_migration.id)

    expect(user_detail.bio).to eq('bio')
  end

  it 'migrates long `bio`' do
    subject

    user_detail = user_details.find_by!(user_id: user_with_long_bio.id)

    expect(user_detail.bio).to eq('a' * 255)
  end

  it 'does not change existing user detail' do
    expect { subject }.not_to change { user_details.find_by!(user_id: user_already_has_details.id).attributes }
  end

  it 'changes existing user detail when the columns are different' do
    expect { subject }.to change { user_details.find_by!(user_id: user_has_different_details.id).bio }.from('bio').to('different')
  end

  it 'does not migrate record' do
    subject

    user_detail = user_details.find_by(user_id: user_needs_no_migration.id)

    expect(user_detail).to be_nil
  end

  it 'does not migrate empty bio' do
    subject

    user_detail = user_details.find_by(user_id: user_also_needs_no_migration.id)

    expect(user_detail).to be_nil
  end
end
