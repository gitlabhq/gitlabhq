# frozen_string_literal: true

RSpec.shared_context 'relation tree restorer shared context' do
  include ImportExport::CommonUtil

  let_it_be(:user) { create(:user) }
  let(:shared) { Gitlab::ImportExport::Shared.new(importable) }
  let(:attributes) { relation_reader.consume_attributes(importable_name) }

  let(:members_mapper) do
    Gitlab::ImportExport::MembersMapper.new(exported_members: {}, user: user, importable: importable)
  end
end
