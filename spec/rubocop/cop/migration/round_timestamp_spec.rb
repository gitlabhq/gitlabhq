# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/round_timestamp'

RSpec.describe RuboCop::Cop::Migration::RoundTimestamp, feature_category: :database do
  let(:config) do
    RuboCop::Config.new('Migration/RoundTimestamp' => { 'EnforcedSince' => 20261005130000 })
  end

  let(:source) do
    <<~RUBY
      class AddIndexToUsers < Gitlab::Database::Migration[2.3]
        milestone '19.5'
      end
    RUBY
  end

  script_advice = 'Run `scripts/refresh-migrations-timestamps` to give new migrations a generated, unique version.'
  manual_advice = 'Rename the file and its `schema_migrations` marker to the current UTC time ' \
    '(`date -u +%Y%m%d%H%M%S`) so the version is unique.'

  def message(version, advice)
    "Migration version #{version} ends in 0000, which suggests it was written by hand. #{advice}"
  end

  shared_examples 'flags a hand-written version' do |path, advice|
    it "registers an offense for #{path}" do
      version = File.basename(path)[/\A\d{14}/]

      expect_offense(<<~RUBY, path)
        class AddIndexToUsers < Gitlab::Database::Migration[2.3]
        ^ #{message(version, advice)}
          milestone '19.5'
        end
      RUBY
    end
  end

  context 'for directories covered by scripts/refresh-migrations-timestamps' do
    it_behaves_like 'flags a hand-written version',
      'db/migrate/20261101090000_add_index_to_users.rb', script_advice
    it_behaves_like 'flags a hand-written version',
      'db/post_migrate/20261101090000_add_index_to_users.rb', script_advice
  end

  context 'for directories not covered by the script' do
    it_behaves_like 'flags a hand-written version',
      'ee/db/geo/migrate/20261101090000_add_index_to_users.rb', manual_advice
    it_behaves_like 'flags a hand-written version',
      'ee/db/embedding/post_migrate/20261101090000_add_index_to_users.rb', manual_advice
    it_behaves_like 'flags a hand-written version',
      'db/click_house/migrate/main/20261101090000_add_index_to_users.rb', manual_advice
  end

  it 'does not register an offense for a generated version' do
    expect_no_offenses(source, 'db/migrate/20261101093412_add_index_to_users.rb')
  end

  it 'does not register an offense for a version ending in 0000 that is not newer than EnforcedSince' do
    expect_no_offenses(source, 'db/post_migrate/20261005130000_add_index_to_users.rb')
    expect_no_offenses(source, 'db/click_house/migrate/main/20260928100000_add_index_to_users.rb')
  end

  it 'does not register an offense for a file without a migration version' do
    expect_no_offenses(source, 'db/migrate/add_index_to_users.rb')
  end

  context 'without EnforcedSince' do
    let(:config) { RuboCop::Config.new('Migration/RoundTimestamp' => {}) }

    it_behaves_like 'flags a hand-written version',
      'db/migrate/20200101000000_add_index_to_users.rb', script_advice
  end
end
