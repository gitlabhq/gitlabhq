# frozen_string_literal: true
require 'spec_helper'

require_migration!

RSpec.describe RemoveNullReleases, feature_category: :release_orchestration do
  let(:releases) { table(:releases) }

  before do
    # we need to migrate to before previous migration so an invalid record can be created
    migrate!
    migration_context.down(previous_migration(3).version)

    releases.create!(tag: 'good', name: 'good release', released_at: Time.now)
    releases.create!(tag: nil, name: 'bad release', released_at: Time.now)
  end

  it 'deletes template records and associated data' do
    expect { migrate! }
      .to change { releases.count }.from(2).to(1)
  end
end
