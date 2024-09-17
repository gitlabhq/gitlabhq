# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Common::Transformers::MemberAttributesTransformer, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:secondary_email) { 'secondary@email.com' }
  let_it_be(:bulk_import) { create(:bulk_import, user: user) }

  shared_examples 'members attribute transformer' do
    let_it_be(:tracker) { create(:bulk_import_tracker, entity: entity) }
    let_it_be(:context) { BulkImports::Pipeline::Context.new(tracker) }

    it 'returns nil when receives no data' do
      expect(subject.transform(context, nil)).to eq(nil)
    end

    it 'returns nil when no user is found' do
      expect(subject.transform(context, member_data)).to eq(nil)
      expect(subject.transform(context, member_data(email: 'inexistent@email.com'))).to eq(nil)
    end

    context 'when the user is not confirmed' do
      before do
        user.update!(confirmed_at: nil)
      end

      it 'returns nil even when the primary email match' do
        data = member_data(email: user.email)

        expect(subject.transform(context, data)).to eq(nil)
      end

      it 'returns nil even when a secondary email match' do
        user.emails << Email.new(email: secondary_email)
        data = member_data(email: secondary_email)

        expect(subject.transform(context, data)).to eq(nil)
      end
    end

    context 'when the user is confirmed' do
      before do
        user.update!(confirmed_at: Time.now.utc)
      end

      it 'finds the user by the primary email' do
        data = member_data(email: user.email)

        expect(subject.transform(context, data)).to eq(
          access_level: 30,
          user_id: user.id,
          created_by_id: user.id,
          created_at: '2020-01-01T00:00:00Z',
          updated_at: '2020-01-01T00:00:00Z',
          expires_at: nil
        )
      end

      it 'finds the user by the secondary email' do
        user.emails << Email.new(email: secondary_email, confirmed_at: Time.now.utc)
        data = member_data(email: secondary_email)

        expect(subject.transform(context, data)).to eq(
          access_level: 30,
          user_id: user.id,
          created_by_id: user.id,
          created_at: '2020-01-01T00:00:00Z',
          updated_at: '2020-01-01T00:00:00Z',
          expires_at: nil
        )
      end

      describe 'format access level' do
        it 'ignores record if no access level is given' do
          data = member_data(email: user.email, access_level: nil)

          expect(subject.transform(context, data)).to be_nil
        end

        it 'ignores record if is not a valid access level' do
          data = member_data(email: user.email, access_level: 999)

          expect(subject.transform(context, data)).to be_nil
        end
      end

      describe 'source user id and username caching' do
        context 'when user gid is present' do
          it 'caches source user id and username' do
            gid = 'gid://gitlab/User/7'
            data = member_data(email: user.email, gid: gid)

            expect_next_instance_of(BulkImports::UsersMapper) do |mapper|
              expect(mapper).to receive(:cache_source_user_id).with('7', user.id)
              expect(mapper).to receive(:cache_source_username).with('source_username', user.username)
            end

            subject.transform(context, data)
          end
        end

        context 'when user gid is missing' do
          it 'does not use caching' do
            data = member_data(email: user.email)

            expect(BulkImports::UsersMapper).not_to receive(:new)

            subject.transform(context, data)
          end
        end

        context 'when username is nil' do
          it 'caches source user id only' do
            gid = 'gid://gitlab/User/7'
            data = nil_username_member_data(email: user.email, gid: gid)

            expect_next_instance_of(BulkImports::UsersMapper) do |mapper|
              expect(mapper).to receive(:cache_source_user_id).with('7', user.id)
              expect(mapper).not_to receive(:cache_source_username)
            end

            subject.transform(context, data)
          end
        end

        context 'when source username matches destination username' do
          it 'caches source user id only' do
            gid = 'gid://gitlab/User/7'
            data = member_data(email: user.email, gid: gid)
            data["user"]["username"] = user.username

            expect_next_instance_of(BulkImports::UsersMapper) do |mapper|
              expect(mapper).to receive(:cache_source_user_id).with('7', user.id)
              expect(mapper).not_to receive(:cache_source_username)
            end

            subject.transform(context, data)
          end
        end
      end
    end

    context 'when importer_user_mapping is enabled' do
      before do
        allow(context).to receive(:importer_user_mapping_enabled?).and_return(true)
      end

      it 'does not transform the data' do
        expect(subject.transform(context, { 'id' => 1 })).to eq({ 'id' => 1 })
      end
    end
  end

  context 'with a project' do
    let_it_be(:entity) { create(:bulk_import_entity, bulk_import: bulk_import, project: project) }
    let_it_be(:project) { create(:project) }

    include_examples 'members attribute transformer'
  end

  context 'with a group' do
    let_it_be(:entity) { create(:bulk_import_entity, bulk_import: bulk_import, group: group) }
    let_it_be(:group) { create(:group) }

    include_examples 'members attribute transformer'
  end

  def member_data(email: '', gid: nil, access_level: 30)
    {
      'created_at' => '2020-01-01T00:00:00Z',
      'updated_at' => '2020-01-01T00:00:00Z',
      'expires_at' => nil,
      'access_level' => {
        'integer_value' => access_level
      },
      'user' => {
        'user_gid' => gid,
        'public_email' => email,
        'username' => 'source_username'
      }
    }
  end

  def nil_username_member_data(email: '', gid: nil, access_level: 30)
    {
      'created_at' => '2020-01-01T00:00:00Z',
      'updated_at' => '2020-01-01T00:00:00Z',
      'expires_at' => nil,
      'access_level' => {
        'integer_value' => access_level
      },
      'user' => {
        'user_gid' => gid,
        'public_email' => email,
        'username' => nil
      }
    }
  end
end
