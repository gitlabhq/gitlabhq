# Testing migrations

In order to reliably test a migration, we need to test it against a database
schema that this migration has been written for. In order to achieve that we
have some _migration helpers_ and RSpec test tag, called `:migration`.

If you want to write a test for a migration consider adding `:migration` tag to
the test signature, like `describe SomeMigrationClass, :migration`.

## How does it work?

Adding a `:migration` tag to a test signature injects a few before / after
hooks to the test.

The most important change is that adding a `:migration` tag adds a `before`
hook that will revert all migrations to the point that a migration under test
is not yet migrated.

In other words, our custom RSpec hooks will find a previous migration, and
migrate the database **down** to the previous migration version.

With this approach you can test a migration against a database schema that this
migration has been written for.

Use `migrate!` helper to run the migration that is under test.

The `after` hook will migrate the database **up** and reinstitutes the latest
schema version, so that the process does not affect subsequent specs and
ensures proper isolation.

## Testing a class that is not an ActiveRecord::Migration

In order to test a class that is not a migration itself, you will need to
manually provide a required schema version. Please add a `schema` tag to a
context that you want to switch the database schema within.

Example: `describe SomeClass, :migration, schema: 20170608152748`.

## Available helpers

Use `table` helper to create a temporary `ActiveRecord::Base` derived model
for a table.

Use `migrate!` helper to run the migration that is under test. It will not only
run migration, but will also bump the schema version in the `schema_migrations`
table. It is necessary because in the `after` hook we trigger the rest of
the migrations, and we need to know where to start.

See `spec/support/migrations_helpers.rb` for all the available helpers.

## An example

```ruby
require 'spec_helper'

# Load a migration class.

require Rails.root.join('db', 'post_migrate', '20170526185842_migrate_pipeline_stages.rb')

describe MigratePipelineStages, :migration do

  # Create test data - pipeline and CI/CD jobs.

  let(:jobs) { table(:ci_builds) }
  let(:stages) { table(:ci_stages) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:projects) { table(:projects) }

  before do
    projects.create!(id: 123, name: 'gitlab1', path: 'gitlab1')
    pipelines.create!(id: 1, project_id: 123, ref: 'master', sha: 'adf43c3a')
    jobs.create!(id: 1, commit_id: 1, project_id: 123, stage_idx: 2, stage: 'build')
    jobs.create!(id: 2, commit_id: 1, project_id: 123, stage_idx: 1, stage: 'test')
  end

  # Test the migration.

  it 'correctly migrates pipeline stages' do
    expect(stages.count).to be_zero

    migrate!

    expect(stages.count).to eq 2
    expect(stages.all.pluck(:name)).to match_array %w[test build]
  end
end
```

## Best practices

1. Note that this type of tests do not run within the transaction, we use
a deletion database cleanup strategy. Do not depend on transaction being
present.
