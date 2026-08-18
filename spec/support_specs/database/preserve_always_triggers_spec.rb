# frozen_string_literal: true

require 'spec_helper'

# Regression coverage for https://gitlab.com/gitlab-org/gitlab/-/work_items/613826.
# DatabaseCleaner's deletion strategy calls Rails' disable_referential_integrity,
# whose trailing `ENABLE TRIGGER ALL` resets tgenabled to 'O', silently dropping
# ALWAYS. A later pg_dump then omits the `ENABLE ALWAYS TRIGGER` line.
RSpec.describe 'Preserving ENABLE ALWAYS triggers across DatabaseCleaner', :delete, feature_category: :database do
  # ci_runner_taggings (the one ALWAYS trigger in the schema) is on the ci connection.
  let(:connection) { Ci::ApplicationRecord.connection }
  let(:trigger_state_sql) do
    <<~SQL
      SELECT t.tgenabled FROM pg_trigger t
      JOIN pg_class c ON c.oid = t.tgrelid
      WHERE c.relname = 'ci_runner_taggings'
        AND t.tgname = 'ci_runner_taggings_heal_tag_id_trigger'
        AND NOT c.relispartition
    SQL
  end

  def trigger_state
    connection.select_value(trigger_state_sql)
  end

  def enable_always_trigger!
    connection.execute(
      'ALTER TABLE ci_runner_taggings ENABLE ALWAYS TRIGGER ci_runner_taggings_heal_tag_id_trigger'
    )
  end

  before do
    enable_always_trigger!
  end

  after do
    enable_always_trigger!
  end

  it 'keeps the trigger enabled ALWAYS after a deletion clean' do
    expect(trigger_state).to eq('A')

    delete_from_all_tables!(except: deletion_except_tables)

    expect(trigger_state).to eq('A')
  end
end
