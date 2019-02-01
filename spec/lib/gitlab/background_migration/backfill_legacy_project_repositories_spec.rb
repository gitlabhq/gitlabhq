# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::BackfillLegacyProjectRepositories, :migration, schema: 20181212171634 do
  it_behaves_like 'backfill migration for project repositories', :legacy
end
