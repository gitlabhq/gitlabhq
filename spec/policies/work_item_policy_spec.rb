# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Layout/LineLength -- defined a work item for every case
RSpec.describe WorkItemPolicy, :aggregate_failures, feature_category: :team_planning do
  let_it_be(:private_group) { create(:group, :private) }
  let_it_be(:public_group) { create(:group, :public) }
  let_it_be(:private_project) { create(:project, :private, group: private_group) }
  let_it_be(:public_project) { create(:project, :public, group: public_group) }

  let_it_be(:admin) { create(:user, :admin) }
  let_it_be(:non_member_user) { create(:user) }

  let_it_be(:guest) { create(:user, guest_of: [private_project, public_project]) }
  let_it_be(:guest_author) { create(:user, guest_of: [private_project, public_project]) }
  let_it_be(:planner) { create(:user, planner_of: [private_project, public_project]) }
  let_it_be(:reporter) { create(:user, reporter_of: [private_project, public_project]) }

  let_it_be(:group_guest) { create(:user, guest_of: [private_group, public_group]) }
  let_it_be(:group_planner) { create(:user, planner_of: [private_group, public_group]) }
  let_it_be(:group_guest_author) { create(:user, guest_of: [private_group, public_group]) }
  let_it_be(:group_reporter) { create(:user, reporter_of: [private_group, public_group]) }

  def permissions(user, work_item)
    described_class.new(user, work_item)
  end

  before do
    stub_application_setting(akismet_enabled: true)
  end

  context 'with project level work items' do
    context 'with private project' do
      let(:project_work_item) { create(:work_item, project: private_project, user_agent_detail: create(:user_agent_detail)) }
      let(:project_confidential_work_item) { create(:work_item, confidential: true, project: private_project, user_agent_detail: create(:user_agent_detail)) }
      let(:authored_project_work_item) { create(:work_item, project: private_project, author: guest_author) }
      let(:authored_project_confidential_work_item) { create(:work_item, confidential: true, project: private_project, author: guest_author) }
      let(:not_persisted_project_work_item) { build(:work_item, project: private_project) }

      it_behaves_like 'checks abilities for project level work items'

      it 'checks non-member abilities' do
        # disallowed
        expect(permissions(non_member_user, project_work_item)).to be_disallowed(
          :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
          :admin_parent_link, :admin_work_item_link, :create_note, :report_spam, :move_work_item, :clone_work_item
        )
        expect(permissions(non_member_user, project_confidential_work_item)).to be_disallowed(
          :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
          :admin_parent_link, :admin_work_item_link, :create_note, :report_spam, :move_work_item, :clone_work_item
        )
      end

      it 'checks non-admin abilities for spam reporting' do
        expect(permissions(guest, project_work_item)).to be_disallowed(:report_spam)
        expect(permissions(non_member_user, project_work_item)).to be_disallowed(:report_spam)
      end

      it 'checks admin abilities for spam reporting' do
        expect(permissions(admin, project_work_item)).to be_allowed(:report_spam)
        expect(permissions(admin, project_confidential_work_item)).to be_allowed(:report_spam)
      end
    end

    context 'with public project' do
      let(:project_work_item) { create(:work_item, project: public_project, user_agent_detail: create(:user_agent_detail)) }
      let(:project_confidential_work_item) { create(:work_item, confidential: true, project: public_project, user_agent_detail: create(:user_agent_detail)) }
      let(:authored_project_work_item) { create(:work_item, project: private_project, author: guest_author) }
      let(:authored_project_confidential_work_item) { create(:work_item, confidential: true, project: private_project, author: guest_author) }
      let(:not_persisted_project_work_item) { build(:work_item, project: public_project) }

      it_behaves_like 'checks abilities for project level work items'

      it 'checks non-member abilities' do
        # allowed
        expect(permissions(non_member_user, project_work_item)).to be_allowed(
          :read_work_item, :read_issue, :read_note, :create_note
        )

        # disallowed
        expect(permissions(non_member_user, project_work_item)).to be_disallowed(
          :admin_work_item, :update_work_item, :delete_work_item,
          :admin_parent_link, :admin_work_item_link, :report_spam, :move_work_item, :clone_work_item
        )
        expect(permissions(non_member_user, project_confidential_work_item)).to be_disallowed(
          :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
          :admin_parent_link, :admin_work_item_link, :create_note, :report_spam, :move_work_item, :clone_work_item
        )
      end

      it 'checks admin abilities for spam reporting' do
        expect(permissions(admin, project_work_item)).to be_allowed(:report_spam)
        expect(permissions(admin, project_confidential_work_item)).to be_allowed(:report_spam)
      end
    end
  end

  context 'with group level work items' do
    context 'with private group' do
      let(:work_item) { create(:work_item, :group_level, namespace: private_group) }
      let(:confidential_work_item) { create(:work_item, :group_level, confidential: true, namespace: private_group) }
      let(:authored_work_item) { create(:work_item, :group_level, namespace: private_group, author: group_guest_author) }
      let(:authored_confidential_work_item) { create(:work_item, :group_level, confidential: true, namespace: private_group, author: group_guest_author) }
      let(:not_persisted_work_item) { build(:work_item, :group_level, namespace: private_group) }

      it_behaves_like 'abilities without group level work items license'
      it_behaves_like 'abilities with group level work items license'

      context 'with group level work items license', if: Gitlab.ee? do
        before do
          stub_licensed_features(epics: true)
        end

        # non-member abilities checks are extracted separately from shared examples because behaviour is different
        # between public and private groups when group level work items licence is enabled.
        it 'checks non-member abilities' do
          # disallowed
          expect(permissions(non_member_user, work_item)).to be_disallowed(
            :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
            :admin_parent_link, :set_work_item_metadata, :admin_work_item_link, :create_note,
            :move_work_item, :clone_work_item
          )
          expect(permissions(non_member_user, confidential_work_item)).to be_disallowed(
            :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
            :admin_parent_link, :set_work_item_metadata, :admin_work_item_link, :create_note,
            :move_work_item, :clone_work_item
          )
        end
      end
    end

    context 'with public group' do
      let(:work_item) { create(:work_item, :group_level, namespace: public_group) }
      let(:confidential_work_item) { create(:work_item, :group_level, confidential: true, namespace: public_group) }
      let(:authored_work_item) { create(:work_item, :group_level, namespace: public_group, author: group_guest_author) }
      let(:authored_confidential_work_item) { create(:work_item, :group_level, confidential: true, namespace: public_group, author: group_guest_author) }
      let(:not_persisted_work_item) { build(:work_item, :group_level, namespace: public_group) }

      it_behaves_like 'abilities without group level work items license'
      it_behaves_like 'abilities with group level work items license'

      context 'with group level work items license', if: Gitlab.ee? do
        before do
          stub_licensed_features(epics: true)
        end

        # non-member abilities checks are extracted separately from shared examples because behaviour is different
        # between public and private groups when group level work items licence is enabled.
        it 'checks non-member abilities' do
          # allowed
          expect(permissions(non_member_user, work_item)).to be_allowed(
            :read_work_item, :read_issue, :read_note, :create_note
          )

          # disallowed
          expect(permissions(non_member_user, work_item)).to be_disallowed(
            :admin_work_item, :update_work_item, :delete_work_item, :admin_parent_link, :set_work_item_metadata,
            :admin_work_item_link, :move_work_item, :clone_work_item
          )
          expect(permissions(non_member_user, confidential_work_item)).to be_disallowed(
            :read_work_item, :read_issue, :read_note, :admin_work_item, :update_work_item, :delete_work_item,
            :admin_parent_link, :set_work_item_metadata, :admin_work_item_link, :create_note,
            :move_work_item, :clone_work_item
          )
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
