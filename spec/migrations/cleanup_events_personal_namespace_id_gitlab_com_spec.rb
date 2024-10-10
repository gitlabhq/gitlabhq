# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupEventsPersonalNamespaceIdGitlabCom, :migration_with_transaction, feature_category: :database do
  before do
    ApplicationRecord.connection.execute('ALTER TABLE events DROP CONSTRAINT check_events_sharding_key_is_not_null')
    ApplicationRecord.connection.execute('ALTER TABLE events DROP CONSTRAINT fk_eea90e3209')
  end

  it 'deletes records referring to deleted namespaces' do
    allow(Gitlab).to receive(:com_except_jh?).and_return(true)

    namespace = table(:namespaces).create!(name: 'name', path: 'path')
    user = table(:users).create!(username: 'john_doe', email: 'johndoe@gitlab.com', projects_limit: 1)

    events = table(:events)
    to_be_kept_1 = events.create!(author_id: user.id, action: 1, personal_namespace_id: namespace.id)
    to_be_kept_2 = events.create!(author_id: user.id, action: 1, personal_namespace_id: nil)
    to_be_deleted = events.create!(author_id: user.id, action: 1, personal_namespace_id: 999_999)

    expect(events.find_by_id(to_be_kept_1.id)).to be_present
    expect(events.find_by_id(to_be_kept_2.id)).to be_present
    expect(events.find_by_id(to_be_deleted.id)).to be_present

    migrate!

    expect(events.find_by_id(to_be_kept_1.id)).to be_present
    expect(events.find_by_id(to_be_kept_2.id)).to be_present
    expect(events.find_by_id(to_be_deleted.id)).not_to be_present
  end
end
