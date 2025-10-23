# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::ArchiveAuthenticationEvents, feature_category: :system_access do
  let(:current_time) { Date.new(2024, 1, 1).beginning_of_day }
  let(:cutoff_time) { current_time - 1.year }

  let(:users_table) { table(:users) }
  let(:organizations_table) { table(:organizations) }

  let(:authentication_events_table) { table(:authentication_events) }
  let(:authentication_event_archived_records_table) { table(:authentication_event_archived_records) }

  let!(:organization) do
    organizations_table.create!(
      id: 1,
      path: 'org',
      name: 'my org',
      visibility_level: 20
    )
  end

  let!(:user) do
    users_table.create!(
      id: 1,
      projects_limit: 1,
      organization_id: 1
    )
  end

  let!(:before_cutoff_record) { create_authentication_event(id: 1, created_at: cutoff_time - 1.hour) }
  let!(:on_cutoff_record) { create_authentication_event(id: 2, created_at: cutoff_time) }
  let!(:after_cutoff_record) { create_authentication_event(id: 3, created_at: cutoff_time + 1.hour) }

  let(:args) do
    min, max = authentication_events_table.pick('MIN(id), MAX(id)')

    {
      start_id: min,
      end_id: max,
      batch_table: 'authentication_events',
      batch_column: 'id',
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ::ApplicationRecord.connection
    }
  end

  subject(:perform_migration) { described_class.new(**args).perform }

  describe "#perform" do
    it "archives records that are a year old or older" do
      freeze_time do
        travel_to(current_time)

        expect { perform_migration }
          .to change { authentication_events_table.count }.by(-2)
          .and change { authentication_event_archived_records_table.count }.by(2)

        expect(authentication_events_table.exists?(before_cutoff_record.id)).to be(false)
        expect(authentication_events_table.exists?(on_cutoff_record.id)).to be(false)
        expect(authentication_events_table.exists?(after_cutoff_record.id)).to be(true)

        expect(authentication_event_archived_records_table.exists?(before_cutoff_record.id)).to be(true)
        expect(authentication_event_archived_records_table.exists?(on_cutoff_record.id)).to be(true)
        expect(authentication_event_archived_records_table.exists?(after_cutoff_record.id)).to be(false)
      end
    end

    it "correctly copies row attributes from operational table to archive table" do
      freeze_time do
        travel_to(current_time)

        original_attrs = before_cutoff_record.serializable_hash

        perform_migration

        archived_attrs = authentication_event_archived_records_table
                           .find_by(id: before_cutoff_record.id)
                           .serializable_hash
        # Assert on archived_at separately because its value is the result of a postgres default. Postgres operations
        # execute outside the scope of Rails frozen time, so we can't match on exact time.
        expect(archived_attrs.except("archived_at")).to match(original_attrs.except('organization_id'))
        expect(archived_attrs["archived_at"]).to be_present
      end
    end

    context "when the associated user has been deleted" do
      before do
        user.destroy!
      end

      it "archives records" do
        freeze_time do
          travel_to(current_time)

          expect { perform_migration }
            .to change { authentication_events_table.count }.by(-2)
            .and change { authentication_event_archived_records_table.count }.by(2)
        end
      end
    end
  end

  private

  def create_authentication_event(id:, created_at:)
    authentication_events_table.create!(
      id: id,
      created_at: created_at,
      user_id: 1,
      user_name: FFaker::Internet.user_name,
      result: AuthenticationEvent.results.values.sample,
      ip_address: FFaker::Internet.ip_v4_address,
      provider: AuthenticationEvent::STATIC_PROVIDERS.sample
    )
  end
end
