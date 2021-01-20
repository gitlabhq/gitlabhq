# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillArtifactExpiryDate, :migration, schema: 20201111152859 do
  subject(:perform) { migration.perform(1, 99) }

  let(:migration) { described_class.new }
  let(:artifact_outside_id_range) { create_artifact!(id: 100, created_at: 1.year.ago, expire_at: nil) }
  let(:artifact_outside_date_range) { create_artifact!(id: 40, created_at: Time.current, expire_at: nil) }
  let(:old_artifact) { create_artifact!(id: 10, created_at: 16.months.ago, expire_at: nil) }
  let(:recent_artifact) { create_artifact!(id: 20, created_at: 1.year.ago, expire_at: nil) }
  let(:artifact_with_expiry) { create_artifact!(id: 30, created_at: 1.year.ago, expire_at: Time.current + 1.day) }

  before do
    table(:namespaces).create!(id: 1, name: 'the-namespace', path: 'the-path')
    table(:projects).create!(id: 1, name: 'the-project', namespace_id: 1)
    table(:ci_builds).create!(id: 1, allow_failure: false)
  end

  context 'when current date is before the 22nd' do
    before do
      travel_to(Time.zone.local(2020, 1, 1, 0, 0, 0))
    end

    it 'backfills the expiry date for old artifacts' do
      expect(old_artifact.reload.expire_at).to eq(nil)

      perform

      expect(old_artifact.reload.expire_at).to be_within(1.minute).of(Time.zone.local(2020, 4, 22, 0, 0, 0))
    end

    it 'backfills the expiry date for recent artifacts' do
      expect(recent_artifact.reload.expire_at).to eq(nil)

      perform

      expect(recent_artifact.reload.expire_at).to be_within(1.minute).of(Time.zone.local(2021, 1, 22, 0, 0, 0))
    end
  end

  context 'when current date is after the 22nd' do
    before do
      travel_to(Time.zone.local(2020, 1, 23, 0, 0, 0))
    end

    it 'backfills the expiry date for old artifacts' do
      expect(old_artifact.reload.expire_at).to eq(nil)

      perform

      expect(old_artifact.reload.expire_at).to be_within(1.minute).of(Time.zone.local(2020, 5, 22, 0, 0, 0))
    end

    it 'backfills the expiry date for recent artifacts' do
      expect(recent_artifact.reload.expire_at).to eq(nil)

      perform

      expect(recent_artifact.reload.expire_at).to be_within(1.minute).of(Time.zone.local(2021, 2, 22, 0, 0, 0))
    end
  end

  it 'does not touch artifacts with expiry date' do
    expect { perform }.not_to change { artifact_with_expiry.reload.expire_at }
  end

  it 'does not touch artifacts outside id range' do
    expect { perform }.not_to change { artifact_outside_id_range.reload.expire_at }
  end

  it 'does not touch artifacts outside date range' do
    expect { perform }.not_to change { artifact_outside_date_range.reload.expire_at }
  end

  private

  def create_artifact!(**args)
    table(:ci_job_artifacts).create!(**args, project_id: 1, job_id: 1, file_type: 1)
  end
end
