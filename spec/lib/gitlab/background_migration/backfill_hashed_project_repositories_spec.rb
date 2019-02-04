# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::BackfillHashedProjectRepositories, :migration, schema: 20181130102132 do
  it_behaves_like 'backfill migration for project repositories', :hashed
end
