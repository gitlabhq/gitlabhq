# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::BackfillLegacyProjectRepositories, :migration, schema: 20181218192239 do
  it_behaves_like 'backfill migration for project repositories', :legacy
end
