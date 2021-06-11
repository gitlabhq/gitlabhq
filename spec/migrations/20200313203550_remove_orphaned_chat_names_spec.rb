# frozen_string_literal: true

require 'spec_helper'
require_migration!('remove_orphaned_chat_names')

RSpec.describe RemoveOrphanedChatNames, schema: 20200313202430 do
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:services) { table(:services) }
  let(:chat_names) { table(:chat_names) }

  let(:namespace) { namespaces.create!(name: 'foo', path: 'foo') }
  let(:project) { projects.create!(namespace_id: namespace.id) }
  let(:service) { services.create!(project_id: project.id, type: 'chat') }
  let(:chat_name) { chat_names.create!(service_id: service.id, team_id: 'TEAM', user_id: 12345, chat_id: 12345) }
  let(:orphaned_chat_name) { chat_names.create!(team_id: 'TEAM', service_id: 0, user_id: 12345, chat_id: 12345) }

  it 'removes the orphaned chat_name' do
    expect(chat_name).to be_present
    expect(orphaned_chat_name).to be_present

    migrate!

    expect(chat_names.where(id: orphaned_chat_name.id)).to be_empty
    expect(chat_name.reload).to be_present
  end
end
