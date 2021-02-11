# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Pipelines::MembersPipeline do
  let_it_be(:member_user1) { create(:user, email: 'email1@email.com') }
  let_it_be(:member_user2) { create(:user, email: 'email2@email.com') }

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:cursor) { 'cursor' }
  let_it_be(:bulk_import) { create(:bulk_import, user: user) }
  let_it_be(:entity) { create(:bulk_import_entity, bulk_import: bulk_import, group: group) }
  let_it_be(:context) { BulkImports::Pipeline::Context.new(entity) }

  describe '#run' do
    it 'maps existing users to the imported group' do
      first_page = member_data(email: member_user1.email, has_next_page: true, cursor: cursor)
      last_page = member_data(email: member_user2.email, has_next_page: false)

      allow_next_instance_of(BulkImports::Common::Extractors::GraphqlExtractor) do |extractor|
        allow(extractor)
          .to receive(:extract)
          .and_return(first_page, last_page)
      end

      expect { subject.run(context) }.to change(GroupMember, :count).by(2)

      members = group.members.map { |m| m.slice(:user_id, :access_level) }

      expect(members).to contain_exactly(
        { user_id: member_user1.id, access_level: 30 },
        { user_id: member_user2.id, access_level: 30 }
      )
    end
  end

  describe 'pipeline parts' do
    it { expect(described_class).to include_module(BulkImports::Pipeline) }
    it { expect(described_class).to include_module(BulkImports::Pipeline::Runner) }

    it 'has extractors' do
      expect(described_class.get_extractor)
        .to eq(
          klass: BulkImports::Common::Extractors::GraphqlExtractor,
          options: {
            query: BulkImports::Groups::Graphql::GetMembersQuery
          }
        )
    end

    it 'has transformers' do
      expect(described_class.transformers)
        .to contain_exactly(
          { klass: BulkImports::Common::Transformers::ProhibitedAttributesTransformer, options: nil },
          { klass: BulkImports::Groups::Transformers::MemberAttributesTransformer, options: nil }
        )
    end

    it 'has loaders' do
      expect(described_class.get_loader).to eq(klass: BulkImports::Groups::Loaders::MembersLoader, options: nil)
    end
  end

  def member_data(email:, has_next_page:, cursor: nil)
    data = {
      'created_at' => '2020-01-01T00:00:00Z',
      'updated_at' => '2020-01-01T00:00:00Z',
      'expires_at' => nil,
      'access_level' => {
        'integer_value' => 30
      },
      'user' => {
        'public_email' => email
      }
    }

    page_info = {
      'end_cursor' => cursor,
      'has_next_page' => has_next_page
    }

    BulkImports::Pipeline::ExtractedData.new(data: data, page_info: page_info)
  end
end
