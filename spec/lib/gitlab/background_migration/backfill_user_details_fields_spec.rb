# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillUserDetailsFields, :migration, schema: 20221111123146 do
  let(:users) { table(:users) }
  let(:user_details) { table(:user_details) }

  let!(:user_all_fields_backfill) do
    users.create!(
      name: generate(:name),
      email: generate(:email),
      projects_limit: 1,
      linkedin: 'linked-in',
      twitter: '@twitter',
      skype: 'skype',
      website_url: 'https://example.com',
      location: 'Antarctica',
      organization: 'Gitlab'
    )
  end

  let!(:user_long_details_fields) do
    length = UserDetail::DEFAULT_FIELD_LENGTH + 1
    users.create!(
      name: generate(:name),
      email: generate(:email),
      projects_limit: 1,
      linkedin: 'l' * length,
      twitter: 't' * length,
      skype: 's' * length,
      website_url: "https://#{'a' * (length - 12)}.com",
      location: 'l' * length,
      organization: 'o' * length
    )
  end

  let!(:user_nil_details_fields) do
    users.create!(
      name: generate(:name),
      email: generate(:email),
      projects_limit: 1
    )
  end

  let!(:user_empty_details_fields) do
    users.create!(
      name: generate(:name),
      email: generate(:email),
      projects_limit: 1,
      linkedin: '',
      twitter: '',
      skype: '',
      website_url: '',
      location: '',
      organization: ''
    )
  end

  let!(:user_with_bio) do
    users.create!(
      name: generate(:name),
      email: generate(:email),
      projects_limit: 1,
      linkedin: 'linked-in',
      twitter: '@twitter',
      skype: 'skype',
      website_url: 'https://example.com',
      location: 'Antarctica',
      organization: 'Gitlab'
    )
  end

  let!(:bio_user_details) do
    user_details
      .find_or_create_by!(user_id: user_with_bio.id)
      .update!(bio: 'bio')
  end

  let!(:user_with_details) do
    users.create!(
      name: generate(:name),
      email: generate(:email),
      projects_limit: 1,
      linkedin: 'linked-in',
      twitter: '@twitter',
      skype: 'skype',
      website_url: 'https://example.com',
      location: 'Antarctica',
      organization: 'Gitlab'
    )
  end

  let!(:existing_user_details) do
    user_details
      .find_or_create_by!(user_id: user_with_details.id)
      .update!(
        linkedin: 'linked-in',
        twitter: '@twitter',
        skype: 'skype',
        website_url: 'https://example.com',
        location: 'Antarctica',
        organization: 'Gitlab'
      )
  end

  let!(:user_different_details) do
    users.create!(
      name: generate(:name),
      email: generate(:email),
      projects_limit: 1,
      linkedin: 'linked-in',
      twitter: '@twitter',
      skype: 'skype',
      website_url: 'https://example.com',
      location: 'Antarctica',
      organization: 'Gitlab'
    )
  end

  let!(:differing_details) do
    user_details
      .find_or_create_by!(user_id: user_different_details.id)
      .update!(
        linkedin: 'details-in',
        twitter: '@details',
        skype: 'details_skype',
        website_url: 'https://details.site',
        location: 'Details Location',
        organization: 'Details Organization'
      )
  end

  let(:user_ids) do
    [
      user_all_fields_backfill,
      user_long_details_fields,
      user_nil_details_fields,
      user_empty_details_fields,
      user_with_bio,
      user_with_details,
      user_different_details
    ].map(&:id)
  end

  subject do
    described_class.new(
      start_id: user_ids.min,
      end_id: user_ids.max,
      batch_table: 'users',
      batch_column: 'id',
      sub_batch_size: 1_000,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  it 'processes all relevant records' do
    expect { subject.perform }.to change { user_details.all.size }.to(5)
  end

  it 'backfills new user_details fields' do
    subject.perform

    user_detail = user_details.find_by!(user_id: user_all_fields_backfill.id)
    expect(user_detail.linkedin).to eq('linked-in')
    expect(user_detail.twitter).to eq('@twitter')
    expect(user_detail.skype).to eq('skype')
    expect(user_detail.website_url).to eq('https://example.com')
    expect(user_detail.location).to eq('Antarctica')
    expect(user_detail.organization).to eq('Gitlab')
  end

  it 'does not migrate nil fields' do
    subject.perform

    expect(user_details.find_by(user_id: user_nil_details_fields)).to be_nil
  end

  it 'does not migrate empty fields' do
    subject.perform

    expect(user_details.find_by(user_id: user_empty_details_fields)).to be_nil
  end

  it 'backfills new fields without overwriting existing `bio` field' do
    subject.perform

    user_detail = user_details.find_by!(user_id: user_with_bio.id)
    expect(user_detail.bio).to eq('bio')
    expect(user_detail.linkedin).to eq('linked-in')
    expect(user_detail.twitter).to eq('@twitter')
    expect(user_detail.skype).to eq('skype')
    expect(user_detail.website_url).to eq('https://example.com')
    expect(user_detail.location).to eq('Antarctica')
    expect(user_detail.organization).to eq('Gitlab')
  end

  context 'when user details are unchanged' do
    it 'does not change existing details' do
      expect { subject.perform }.not_to change {
        user_details.find_by!(user_id: user_with_details.id).attributes
      }
    end
  end

  context 'when user details are changed' do
    it 'updates existing user details' do
      expect { subject.perform }.to change {
        user_details.find_by!(user_id: user_different_details.id).attributes
      }

      user_detail = user_details.find_by!(user_id: user_different_details.id)
      expect(user_detail.linkedin).to eq('linked-in')
      expect(user_detail.twitter).to eq('@twitter')
      expect(user_detail.skype).to eq('skype')
      expect(user_detail.website_url).to eq('https://example.com')
      expect(user_detail.location).to eq('Antarctica')
      expect(user_detail.organization).to eq('Gitlab')
    end
  end
end
