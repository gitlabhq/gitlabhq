# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillHashedProjectRepositories do
  it_behaves_like 'backfill migration for project repositories', :hashed
end
