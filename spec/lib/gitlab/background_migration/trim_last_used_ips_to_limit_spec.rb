# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::TrimLastUsedIpsToLimit, feature_category: :system_access do
  let(:connection) { ApplicationRecord.connection }
  let(:organizations) { table(:organizations) }
  let(:users) { table(:users) }
  let(:personal_access_tokens) { table(:personal_access_tokens) }
  let(:last_used_ips) { table(:personal_access_token_last_used_ips) }
  let(:sub_batch_size) { 100 }

  let!(:organization) { organizations.create!(name: 'org', path: 'org') }

  let(:migration) do
    described_class.new(
      start_cursor: [last_used_ips.minimum(:id)],
      end_cursor: [last_used_ips.maximum(:id)],
      batch_table: :personal_access_token_last_used_ips,
      batch_column: :id,
      sub_batch_size: sub_batch_size,
      pause_ms: 0,
      connection: connection
    )
  end

  def create_token
    suffix = SecureRandom.hex(8)
    user = users.create!(
      username: "user_#{suffix}", email: "user_#{suffix}@example.com",
      user_type: 0, projects_limit: 10, organization_id: organization.id
    )
    personal_access_tokens.create!(name: "pat_#{suffix}", user_id: user.id, organization_id: organization.id)
  end

  # Creates a token, then `count` IP rows for it (oldest first), returning the
  # token and the IP rows newest-first so tests can assert which survive.
  def create_token_with_ips(count)
    token = create_token
    rows = Array.new(count) do |i|
      last_used_ips.create!(
        personal_access_token_id: token.id,
        organization_id: organization.id,
        ip_address: "192.0.2.#{i + 1}",
        created_at: (count - i).minutes.ago,
        updated_at: Time.current
      )
    end
    [token, rows.sort_by(&:created_at).reverse]
  end

  def ip_ids_for(token)
    last_used_ips.where(personal_access_token_id: token.id).pluck(:id)
  end

  describe '#perform' do
    it 'keeps only the five most recent IPs per token and deletes the rest' do
      token, newest_first = create_token_with_ips(8)

      migration.perform

      expect(ip_ids_for(token)).to match_array(newest_first.first(5).map(&:id))
    end

    it 'leaves tokens at or under the limit untouched' do
      create_token_with_ips(5)
      create_token_with_ips(1)

      expect { migration.perform }.not_to change { last_used_ips.count }
    end

    it 'trims each token independently within the same batch' do
      over_token, over = create_token_with_ips(7)
      under_token, under = create_token_with_ips(3)

      migration.perform

      expect(ip_ids_for(over_token)).to match_array(over.first(5).map(&:id))
      expect(ip_ids_for(under_token)).to match_array(under.map(&:id))
    end

    it 'is idempotent' do
      token, = create_token_with_ips(9)

      migration.perform
      expect(ip_ids_for(token).count).to eq(5)

      expect { migration.perform }.not_to change { ip_ids_for(token).count }
    end

    it 'keeps only the most recent occurrence of each IP, capped at IPS_TO_KEEP unique IPs' do
      token = create_token

      # Two IPs recorded twice (old + newer), plus four more unique IPs.
      rows = [
        ['192.0.2.1', 10.minutes.ago],
        ['192.0.2.1', 1.minute.ago],
        ['192.0.2.2', 9.minutes.ago],
        ['192.0.2.2', 2.minutes.ago],
        ['192.0.2.3', 3.minutes.ago],
        ['192.0.2.4', 4.minutes.ago],
        ['192.0.2.5', 5.minutes.ago],
        ['192.0.2.6', 6.minutes.ago]
      ].map do |ip, created_at|
        last_used_ips.create!(
          personal_access_token_id: token.id, organization_id: organization.id,
          ip_address: ip, created_at: created_at, updated_at: Time.current
        )
      end
      newest_dup = rows[1] # 192.0.2.1 at 1.minute.ago

      migration.perform

      surviving = last_used_ips.where(personal_access_token_id: token.id)

      # No duplicates remain and the cap holds.
      expect(surviving.count).to eq(described_class::IPS_TO_KEEP)
      expect(surviving.distinct.count(:ip_address)).to eq(described_class::IPS_TO_KEEP)

      # The five most recent distinct IPs survive; the oldest is dropped.
      expect(surviving.pluck(:ip_address).map(&:to_s))
        .to match_array(['192.0.2.1', '192.0.2.2', '192.0.2.3', '192.0.2.4', '192.0.2.5'])

      # The surviving 192.0.2.1 row is its newest occurrence, not the stale one.
      expect(surviving.where(ip_address: '192.0.2.1').pluck(:id)).to eq([newest_dup.id])
    end
  end
end
