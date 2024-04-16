# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Common::Pipelines::MembersPipeline, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:bulk_import) { create(:bulk_import, user: user) }
  let_it_be(:member_user1) { create(:user, email: 'email1@email.com') }
  let_it_be(:member_user2) { create(:user, email: 'email2@email.com') }
  let_it_be(:member_data) do
    {
      user_id: member_user1.id,
      created_by_id: member_user2.id,
      access_level: 30,
      created_at: '2020-01-01T00:00:00Z',
      updated_at: '2020-01-01T00:00:00Z',
      expires_at: nil
    }
  end

  let(:parent) { create(:group) }
  let(:tracker) { create(:bulk_import_tracker, entity: entity) }
  let(:context) { BulkImports::Pipeline::Context.new(tracker) }
  let(:members) { portable.members.map { |m| m.slice(:user_id, :access_level) } }

  subject(:pipeline) { described_class.new(context) }

  before do
    allow(pipeline).to receive(:set_source_objects_counter)
  end

  def extracted_data(email:, has_next_page: false)
    data = {
      'created_at' => '2020-01-01T00:00:00Z',
      'updated_at' => '2020-01-02T00:00:00Z',
      'expires_at' => nil,
      'access_level' => {
        'integer_value' => 30
      },
      'user' => {
        'public_email' => email
      }
    }

    page_info = {
      'has_next_page' => has_next_page,
      'next_page' => has_next_page ? 'cursor' : nil
    }

    BulkImports::Pipeline::ExtractedData.new(data: data, page_info: page_info)
  end

  shared_examples 'members import' do
    before do
      portable.members.delete_all
    end

    describe '#run' do
      it 'creates memberships for existing users' do
        first_page = extracted_data(email: member_user1.email, has_next_page: true)
        last_page = extracted_data(email: member_user2.email)

        allow_next_instance_of(BulkImports::Common::Extractors::GraphqlExtractor) do |extractor|
          allow(extractor).to receive(:extract).and_return(first_page, last_page)
        end

        expect { pipeline.run }.to change(portable.members, :count).by(2)

        expect(members).to contain_exactly(
          { user_id: member_user1.id, access_level: 30 },
          { user_id: member_user2.id, access_level: 30 }
        )
      end
    end

    describe '#load' do
      it 'creates new membership' do
        expect { subject.load(context, member_data) }.to change(portable.members, :count).by(1)

        member = portable.members.find_by_user_id(member_user1.id)

        expect(member.user).to eq(member_user1)
        expect(member.created_by).to eq(member_user2)
        expect(member.access_level).to eq(30)
        expect(member.created_at).to eq('2020-01-01T00:00:00Z')
        expect(member.updated_at).to eq('2020-01-01T00:00:00Z')
        expect(member.expires_at).to eq(nil)
      end

      it 'does not send new member notification' do
        expect(NotificationService).not_to receive(:new)

        subject.load(context, member_data)
      end

      context 'when user_id is current user id' do
        it 'does not create new membership' do
          data = { user_id: user.id }

          expect { pipeline.load(context, data) }.not_to change(portable.members, :count)
        end
      end

      context 'when data is nil' do
        it 'does not create new membership' do
          expect { pipeline.load(context, nil) }.not_to change(portable.members, :count)
        end
      end

      context 'when user membership already exists with the same access level' do
        it 'does not create new membership' do
          portable.members.create!(member_data)

          expect { pipeline.load(context, member_data) }.not_to change(portable.members, :count)
        end
      end

      context 'when portable is in a parent group' do
        let(:tracker) { create(:bulk_import_tracker, entity: entity_with_parent) }

        before do
          parent.members.create!(member_data)
        end

        context 'when the same membership exists in parent group' do
          it 'does not create new membership' do
            expect { pipeline.load(context, member_data) }.not_to change(portable_with_parent.members, :count)
          end
        end

        context 'when membership has higher access level than membership in parent group' do
          it 'creates new direct membership' do
            data = member_data.merge(access_level: Gitlab::Access::MAINTAINER)

            expect { pipeline.load(context, data) }.to change(portable_with_parent.members, :count)

            member = portable_with_parent.members.find_by_user_id(member_user1.id)

            expect(member.access_level).to eq(Gitlab::Access::MAINTAINER)
          end
        end

        context 'when membership has lower access level than membership in parent group' do
          it 'does not create new membership' do
            data = member_data.merge(access_level: Gitlab::Access::GUEST)

            expect { pipeline.load(context, data) }.not_to change(portable_with_parent.members, :count)
          end
        end
      end
    end
  end

  context 'when importing to group' do
    let_it_be(:portable) { create(:group) }

    let(:portable_with_parent) { create(:group, parent: parent) }
    let(:entity) { create(:bulk_import_entity, :group_entity, group: portable, bulk_import: bulk_import) }
    let(:entity_with_parent) { create(:bulk_import_entity, :group_entity, group: portable_with_parent, bulk_import: bulk_import) }

    include_examples 'members import'

    context 'when user is a member of group through group sharing' do
      before_all do
        group = create(:group)
        group.add_developer(member_user1)
        create(:group_group_link, shared_group: portable, shared_with_group: group)
      end

      it 'does not create new membership' do
        expect { pipeline.load(context, member_data) }.not_to change(Member, :count)
      end

      context 'when membership is a higher access level' do
        it 'creates new direct membership' do
          data = member_data.merge(access_level: Gitlab::Access::MAINTAINER)

          expect { pipeline.load(context, data) }.to change(portable.members, :count).by(1)

          member = portable.members.find_by_user_id(member_user1.id)

          expect(member.access_level).to eq(Gitlab::Access::MAINTAINER)
        end
      end
    end
  end

  context 'when importing to project' do
    let_it_be(:portable) { create(:project) }

    let(:portable_with_parent) { create(:project, namespace: parent) }
    let(:entity) { create(:bulk_import_entity, :project_entity, project: portable, bulk_import: bulk_import) }
    let(:entity_with_parent) { create(:bulk_import_entity, :project_entity, project: portable_with_parent, bulk_import: bulk_import) }

    include_examples 'members import'

    context 'when project is shared with a group, and user is a direct member of the group' do
      before_all do
        group = create(:group)
        group.add_developer(member_user1)
        create(:project_group_link, project: portable, group: group)
      end

      it 'does not create new membership' do
        expect { pipeline.load(context, member_data) }.not_to change(Member, :count)
      end

      context 'when membership is a higher access level' do
        it 'creates new direct membership' do
          data = member_data.merge(access_level: Gitlab::Access::MAINTAINER)

          expect { pipeline.load(context, data) }.to change(portable.members, :count).by(1)

          member = portable.members.find_by_user_id(member_user1.id)

          expect(member.access_level).to eq(Gitlab::Access::MAINTAINER)
        end
      end
    end

    context 'when parent group is shared with other group, and user is a member of other group' do
      let(:tracker) { create(:bulk_import_tracker, entity: entity_with_parent) }

      before do
        group = create(:group)
        group.add_developer(member_user1)
        create(:group_group_link, shared_group: parent, shared_with_group: group)
      end

      it 'does not create new membership' do
        expect { pipeline.load(context, member_data) }.not_to change(Member, :count)
      end

      context 'when membership is a higher access level' do
        it 'creates new direct membership' do
          data = member_data.merge(access_level: Gitlab::Access::MAINTAINER)

          expect { pipeline.load(context, data) }.to change(portable_with_parent.members, :count).by(1)

          member = portable_with_parent.members.find_by_user_id(member_user1.id)

          expect(member.access_level).to eq(Gitlab::Access::MAINTAINER)
        end
      end
    end
  end
end
