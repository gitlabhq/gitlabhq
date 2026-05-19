# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::Projects::CreatorService, feature_category: :groups_and_projects do
  let_it_be(:source, reload: true) { create(:project, :public) }
  let_it_be(:source2, reload: true) { create(:project, :public) }
  let_it_be(:user) { create(:user) }

  describe '.access_levels' do
    it 'returns Gitlab::Access.sym_options_with_owner' do
      expect(described_class.access_levels).to eq(Gitlab::Access.sym_options_with_owner)
    end
  end

  describe '.add_members' do
    it_behaves_like 'bulk member creation' do
      let_it_be(:source_type) { Project }
      let_it_be(:member_type) { ProjectMember }
    end
  end

  describe '.add_member' do
    it_behaves_like 'member creation' do
      let_it_be(:member_type) { ProjectMember }
    end

    it_behaves_like 'member creation with organization isolation' do
      let_it_be(:source_type) { Project }
    end

    context 'authorized projects update' do
      it 'schedules a single project authorization update job when called multiple times' do
        stub_feature_flags(do_not_run_safety_net_auth_refresh_jobs: false)

        expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker).to receive(:bulk_perform_in).once

        1.upto(3) do
          described_class.add_member(source, user, :maintainer)
        end
      end
    end

    context 'when adding the creator as owner in a personal project' do
      let_it_be(:current_user) { create(:user, :with_namespace) }
      let_it_be(:personal_project) do
        create(:project, namespace: current_user.namespace, organization: current_user.namespace.organization)
      end

      context 'when the user is not a member of the project organization' do
        before do
          personal_project.members.find_by(user_id: current_user.id)&.destroy!
          Organizations::OrganizationUser.where(
            user_id: current_user.id,
            organization_id: personal_project.organization_id
          ).delete_all
        end

        it 'bypasses the organization check and creates the member' do
          member = described_class.add_member(personal_project, current_user, :owner, current_user: current_user)
          expect(member).to be_persisted
        end
      end
    end

    context 'with immediately_sync_authorizations: true' do
      it 'immediate creates a ProjectAuthorization' do
        described_class.add_member(source, user, :maintainer, immediately_sync_authorizations: true)

        expect(
          ProjectAuthorization.where(
            user: user, project: source,
            access_level: Gitlab::Access::MAINTAINER)
        ).to exist
      end
    end

    context 'service account membership eligibility' do
      let_it_be(:maintainer) { create(:user, maintainer_of: source) }

      context 'when the service account is not eligible for membership' do
        let_it_be(:other_project) { create(:project, namespace: source.namespace) }
        let(:ineligible_sa) do
          create(:user, :service_account).tap do |u|
            u.user_detail.update!(provisioned_by_project_id: other_project.id)
          end
        end

        it 'does not create the member when inviting cross-project' do
          member = described_class.add_member(source, ineligible_sa, :developer, current_user: maintainer)

          expect(member).not_to be_persisted
          expect(member.errors.full_messages).to include(/not authorized to create member/)
        end
      end

      context 'when the service account is eligible for membership' do
        let(:eligible_sa) do
          create(:user, :service_account).tap do |u|
            u.user_detail.update!(provisioned_by_project_id: source.id)
          end
        end

        it 'creates the member' do
          member = described_class.add_member(source, eligible_sa, :developer, current_user: maintainer)

          expect(member).to be_persisted
        end
      end
    end
  end
end
