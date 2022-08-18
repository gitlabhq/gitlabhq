# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RemoveAllTraceExpirationDates, :migration,
               :suppress_gitlab_schemas_validate_connection, schema: 20220131000001 do
  subject(:perform) { migration.perform(1, 99) }

  let(:migration) { described_class.new }

  let(:trace_in_range)         { create_trace!(id: 10,   created_at: Date.new(2020, 06, 20), expire_at: Date.new(2021, 01, 22)) }
  let(:trace_outside_range)    { create_trace!(id: 40,   created_at: Date.new(2020, 06, 22), expire_at: Date.new(2021, 01, 22)) }
  let(:trace_without_expiry)   { create_trace!(id: 30,   created_at: Date.new(2020, 06, 21), expire_at: nil) }
  let(:archive_in_range)       { create_archive!(id: 10, created_at: Date.new(2020, 06, 20), expire_at: Date.new(2021, 01, 22)) }
  let(:trace_outside_id_range) { create_trace!(id: 100,  created_at: Date.new(2020, 06, 20), expire_at: Date.new(2021, 01, 22)) }

  before do
    table(:namespaces).create!(id: 1, name: 'the-namespace', path: 'the-path')
    table(:projects).create!(id: 1, name: 'the-project', namespace_id: 1)
    table(:ci_builds).create!(id: 1, allow_failure: false)
  end

  context 'for self-hosted instances' do
    it 'sets expire_at for artifacts in range to nil' do
      expect { perform }.not_to change { trace_in_range.reload.expire_at }
    end

    it 'does not change expire_at timestamps that are not set to midnight' do
      expect { perform }.not_to change { trace_outside_range.reload.expire_at }
    end

    it 'does not change expire_at timestamps that are set to midnight on a day other than the 22nd' do
      expect { perform }.not_to change { trace_without_expiry.reload.expire_at }
    end

    it 'does not touch artifacts outside id range' do
      expect { perform }.not_to change { archive_in_range.reload.expire_at }
    end

    it 'does not touch artifacts outside date range' do
      expect { perform }.not_to change { trace_outside_id_range.reload.expire_at }
    end
  end

  private

  def create_trace!(**args)
    table(:ci_job_artifacts).create!(**args, project_id: 1, job_id: 1, file_type: 3)
  end

  def create_archive!(**args)
    table(:ci_job_artifacts).create!(**args, project_id: 1, job_id: 1, file_type: 1)
  end
end
