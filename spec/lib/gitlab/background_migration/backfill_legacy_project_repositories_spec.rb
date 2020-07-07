# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillLegacyProjectRepositories do
  it_behaves_like 'backfill migration for project repositories', :legacy
end
