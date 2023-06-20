# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::ApproveAccessRequestService, feature_category: :groups_and_projects do
  let(:project) { create(:project, :public) }
  let(:group) { create(:group, :public) }
  let(:current_user) { create(:user) }
  let(:access_requester_user) { create(:user) }
  let(:access_requester) { source.requesters.find_by!(user_id: access_requester_user.id) }
  let(:opts) { {} }
  let(:params) { {} }
  let(:custom_access_level) { Gitlab::Access::MAINTAINER }

  shared_examples 'a service raising Gitlab::Access::AccessDeniedError' do
    it 'raises Gitlab::Access::AccessDeniedError' do
      expect do
        described_class.new(current_user, params).execute(access_requester, **opts)
      end.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  shared_examples 'a service approving an access request' do
    it 'succeeds' do
      expect do
        described_class.new(current_user, params).execute(access_requester, **opts)
      end.to change { source.requesters.count }.by(-1)
    end

    it 'returns a <Source>Member' do
      member = described_class.new(current_user, params).execute(access_requester, **opts)

      expect(member).to be_a "#{source.class}Member".constantize
      expect(member.requested_at).to be_nil
    end

    it 'calls the method to resolve access request for the approver' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:resolve_access_request_todos).with(access_requester)
      end

      described_class.new(current_user, params).execute(access_requester, **opts)
    end

    it 'resolves the todos for the access requests' do
      expect_next_instance_of(TodoService) do |instance|
        expect(instance).to receive(:resolve_access_request_todos).with(access_requester)
      end

      described_class.new(current_user, params).execute(access_requester, **opts)
    end

    context 'with a custom access level' do
      let(:params) { { access_level: custom_access_level } }

      it 'returns a ProjectMember with the custom access level' do
        member = described_class.new(current_user, params).execute(access_requester, **opts)

        expect(member.access_level).to eq(custom_access_level)
      end
    end
  end

  context 'when an access requester is found' do
    before do
      project.request_access(access_requester_user)
      group.request_access(access_requester_user)
    end

    context 'when current user is nil' do
      let(:user) { nil }

      context 'and :ldap option is not given' do
        it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
          let(:source) { project }
        end

        it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
          let(:source) { group }
        end
      end

      context 'and :skip_authorization option is false' do
        let(:opts) { { skip_authorization: false } }

        it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
          let(:source) { project }
        end

        it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
          let(:source) { group }
        end
      end

      context 'and :skip_authorization option is true' do
        let(:opts) { { skip_authorization: true } }

        it_behaves_like 'a service approving an access request' do
          let(:source) { project }
        end

        it_behaves_like 'a service approving an access request' do
          let(:source) { group }
        end
      end
    end

    context 'when current user cannot approve access request to the project' do
      it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
        let(:source) { project }
      end

      it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
        let(:source) { group }
      end
    end

    context 'when current user can approve access request to the project' do
      before do
        project.add_maintainer(current_user)
        group.add_owner(current_user)
      end

      it_behaves_like 'a service approving an access request' do
        let(:source) { project }
      end

      it_behaves_like 'a service approving an access request' do
        let(:source) { group }
      end
    end

    context 'in a project' do
      let_it_be(:group_project) { create(:project, :public, group: create(:group, :public)) }

      let(:source) { group_project }
      let(:custom_access_level) { Gitlab::Access::OWNER }
      let(:params) { { access_level: custom_access_level } }

      before do
        group_project.request_access(access_requester_user)
      end

      context 'maintainers' do
        before do
          group_project.add_maintainer(current_user)
        end

        context 'cannot approve the access request of a requester to give them OWNER permissions' do
          it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError'
        end
      end

      context 'owners' do
        before do
          # so that `current_user` is considered an `OWNER` in the project via inheritance.
          group_project.group.add_owner(current_user)
        end

        context 'can approve the access request of a requester to give them OWNER permissions' do
          it_behaves_like 'a service approving an access request'
        end
      end
    end
  end
end
