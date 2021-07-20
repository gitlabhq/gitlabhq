# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DatabaseImporters::InstanceAdministrators::CreateGroup do
  describe '#execute' do
    let(:result) { subject.execute }

    context 'without application_settings' do
      it 'returns error' do
        expect(subject).to receive(:log_error).and_call_original
        expect(result).to eq(
          status: :error,
          message: 'No application_settings found',
          last_step: :validate_application_settings
        )

        expect(Group.count).to eq(0)
      end
    end

    context 'without admin users' do
      let(:application_setting) { Gitlab::CurrentSettings.current_application_settings }

      before do
        allow(ApplicationSetting).to receive(:current_without_cache) { application_setting }
      end

      it 'returns error' do
        expect(subject).to receive(:log_error).and_call_original
        expect(result).to eq(
          status: :error,
          message: 'No active admin user found',
          last_step: :validate_admins
        )

        expect(Group.count).to eq(0)
      end
    end

    context 'with application settings and admin users', :do_not_mock_admin_mode_setting do
      let(:group) { result[:group] }
      let(:application_setting) { Gitlab::CurrentSettings.current_application_settings }

      let!(:user) { create(:user, :admin) }

      before do
        allow(ApplicationSetting).to receive(:current_without_cache) { application_setting }
      end

      it 'returns correct keys' do
        expect(result.keys).to contain_exactly(
          :status, :group
        )
      end

      it "tracks successful install" do
        expect(::Gitlab::Tracking).to receive(:event).with(
          'instance_administrators_group', 'group_created', namespace: group
        )

        subject.execute
      end

      it 'creates group' do
        expect(result[:status]).to eq(:success)
        expect(group).to be_persisted
        expect(group.name).to eq('GitLab Instance')
        expect(group.path).to start_with('gitlab-instance')
        expect(group.path.split('-').last.length).to eq(8)
        expect(group.visibility_level).to eq(described_class::VISIBILITY_LEVEL)
      end

      it 'adds all admins as maintainers' do
        admin1 = create(:user, :admin)
        admin2 = create(:user, :admin)
        create(:user)

        expect(result[:status]).to eq(:success)
        expect(group.members.collect(&:user)).to contain_exactly(user, admin1, admin2)
        expect(group.members.collect(&:access_level)).to contain_exactly(
          Gitlab::Access::OWNER,
          Gitlab::Access::MAINTAINER,
          Gitlab::Access::MAINTAINER
        )
      end

      it 'saves the group id' do
        expect(result[:status]).to eq(:success)
        expect(application_setting.instance_administrators_group_id).to eq(group.id)
      end

      it 'returns error when saving group ID fails' do
        allow(application_setting).to receive(:save) { false }

        expect(result).to eq(
          status: :error,
          message: 'Could not save group ID',
          last_step: :save_group_id
        )
      end

      context 'when group already exists' do
        let(:existing_group) { create(:group) }

        before do
          admin1 = create(:user, :admin)
          admin2 = create(:user, :admin)

          existing_group.add_owner(user)
          existing_group.add_users([admin1, admin2], Gitlab::Access::MAINTAINER)

          application_setting.instance_administrators_group_id = existing_group.id
        end

        it 'returns success' do
          expect(result).to eq(
            status: :success,
            group: existing_group
          )

          expect(Group.count).to eq(1)
        end
      end

      context 'when group cannot be created' do
        let(:group) { build(:group) }

        before do
          group.errors.add(:base, "Test error")

          expect_next_instance_of(::Groups::CreateService) do |group_create_service|
            expect(group_create_service).to receive(:execute)
              .and_return(group)
          end
        end

        it 'returns error' do
          expect(subject).to receive(:log_error).and_call_original
          expect(result).to eq(
            status: :error,
            message: 'Could not create group',
            last_step: :create_group
          )
        end
      end

      context 'when user cannot be added to group' do
        before do
          subject.instance_variable_set(:@instance_admins, [user, build(:user, :admin)])
        end

        it 'returns error' do
          expect(subject).to receive(:log_error).and_call_original
          expect(result).to eq(
            status: :error,
            message: 'Could not add admins as members',
            last_step: :add_group_members
          )
        end
      end
    end
  end
end
