# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Loaders::MembersLoader do
  describe '#load' do
    let_it_be(:user_importer) { create(:user) }
    let_it_be(:user_member) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:bulk_import) { create(:bulk_import, user: user_importer) }
    let_it_be(:entity) { create(:bulk_import_entity, bulk_import: bulk_import, group: group) }
    let_it_be(:context) { BulkImports::Pipeline::Context.new(entity) }

    let_it_be(:data) do
      {
        'user_id' => user_member.id,
        'created_by_id' => user_importer.id,
        'access_level' => 30,
        'created_at' => '2020-01-01T00:00:00Z',
        'updated_at' => '2020-01-01T00:00:00Z',
        'expires_at' => nil
      }
    end

    it 'does nothing when there is no data' do
      expect { subject.load(context, nil) }.not_to change(GroupMember, :count)
    end

    it 'creates the member' do
      expect { subject.load(context, data) }.to change(GroupMember, :count).by(1)

      member = group.members.last

      expect(member.user).to eq(user_member)
      expect(member.created_by).to eq(user_importer)
      expect(member.access_level).to eq(30)
      expect(member.created_at).to eq('2020-01-01T00:00:00Z')
      expect(member.updated_at).to eq('2020-01-01T00:00:00Z')
      expect(member.expires_at).to eq(nil)
    end
  end
end
