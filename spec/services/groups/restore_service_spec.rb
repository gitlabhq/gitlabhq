# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::RestoreService, feature_category: :groups_and_projects do
  let(:user) { create(:user) }
  let(:group) do
    create(:group_with_deletion_schedule,
      marked_for_deletion_on: 1.day.ago,
      deleting_user: user).tap do |g|
        g.update!(path: "group-1-deletion_scheduled-#{g.id}", name: "Group1 Name-deletion_scheduled-#{g.id}")
      end
  end

  subject(:execute) { described_class.new(group, user).execute }

  context 'when restoring group' do
    context 'with a user that can admin the group' do
      before do
        group.add_owner(user)
      end

      context 'for a group that has been marked for deletion' do
        it 'removes the mark for deletion' do
          execute

          expect(group.deletion_schedule).to be_nil
          expect(group.marked_for_deletion_on).to be_nil
          expect(group.deleting_user).to be_nil
        end

        it 'returns success' do
          result = execute

          expect(result).to be_success
        end

        context 'when the original group path is not taken' do
          it 'renames the group back to its original path' do
            expect { execute }.to change { group.path }.from("group-1-deletion_scheduled-#{group.id}").to("group-1")
          end

          it 'renames the group back to its original name' do
            expect { execute }.to change { group.name }.from("Group1 Name-deletion_scheduled-#{group.id}")
              .to("Group1 Name")
          end
        end

        context 'when the original group name has been taken' do
          before do
            create(:group, path: 'group-1', name: 'Group1 Name')
          end

          it 'renames the group back to its original path with a suffix' do
            expect { execute }.to change { group.path }
              .from("group-1-deletion_scheduled-#{group.id}")
              .to(/group-1-[a-zA-Z0-9]{5}/)
          end

          it 'renames the group back to its original name with a suffix' do
            expect { execute }.to change { group.name }.from("Group1 Name-deletion_scheduled-#{group.id}")
              .to(/Group1 Name-[a-zA-Z0-9]{5}/)
          end

          it 'uses the same suffix for both the path and name' do
            execute

            path_suffix = group.path.split('-')[-1]
            name_suffix = group.name.split('-')[-1]

            expect(path_suffix).to eq(name_suffix)
          end
        end

        context "when the original group path does not contain the -deletion_scheduled- suffix" do
          let(:group) do
            create(:group_with_deletion_schedule,
              marked_for_deletion_on: 1.day.ago,
              deleting_user: user)
          end

          it 'renames the group back to its original path' do
            expect { execute }.not_to change { group.path }
          end

          it 'renames the group back to its original name' do
            expect { execute }.not_to change { group.name }
          end
        end

        context 'when group renaming fails' do
          before do
            allow_next_instance_of(Groups::UpdateService) do |group_update_service|
              allow(group_update_service).to receive(:execute).and_return(false)
              allow(group).to receive_message_chain(:errors, :full_messages)
                .and_return(['error message'])
            end
          end

          it 'returns error' do
            result = execute

            expect(result).to be_error
            expect(result.message).to eq('error message')
          end
        end

        context 'when deletion schedule destroy fails' do
          before do
            allow(group.deletion_schedule).to receive(:destroy).and_return(false)
          end

          it 'returns error' do
            result = execute

            expect(result).to be_error
            expect(result.message).to eq('Could not restore the group')
          end
        end
      end

      context 'when the group is deletion is in progress' do
        before do
          group.namespace_details.update!(deleted_at: Time.current)
        end

        it 'returns error' do
          result = execute

          expect(result).to be_error
          expect(result.message).to eq('Group deletion is in progress')
        end
      end

      context 'for a group that has not been marked for deletion' do
        let(:group) { create(:group) }

        it 'does not change the attributes associated with delayed deletion' do
          execute

          expect(group.self_deletion_scheduled_deletion_created_on).to be_nil
          expect(group.deleting_user).to be_nil
        end

        it 'returns error' do
          result = execute

          expect(result).to be_error
          expect(result.message).to eq('Group has not been marked for deletion')
        end
      end

      it 'logs the restore' do
        allow(Gitlab::AppLogger).to receive(:info)
        expect(::Gitlab::AppLogger).to receive(:info)
          .with("User #{user.id} restored group #{group.full_path.sub(described_class::DELETED_SUFFIX_REGEX, '')}")

        execute
      end
    end

    context 'with a user that cannot admin the group' do
      it 'does not restore the group' do
        execute

        expect(group).to be_self_deletion_scheduled
      end

      it 'returns error' do
        result = execute

        expect(result).to be_error
        expect(result.message).to eq('You are not authorized to perform this action')
      end
    end
  end
end
