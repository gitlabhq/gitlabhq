# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::ApproveAccessRequestService, feature_category: :groups_and_projects do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:access_requester_user) { create(:user) }
  let(:access_requester) { source.requesters.find_by!(user_id: access_requester_user.id) }
  let(:opts) { {} }
  let(:params) { {} }

  shared_examples 'a service raising Gitlab::Access::AccessDeniedError' do
    let(:params) { { access_level: access_level_to_assign }.compact }
    let(:access_level_to_assign) { nil }

    it 'raises Gitlab::Access::AccessDeniedError' do
      expect do
        described_class.new(current_user, params).execute(access_requester, **opts)
      end.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  shared_examples 'a service approving an access request' do
    let(:access_level_to_assign) { Gitlab::Access::MAINTAINER }

    it 'succeeds' do
      expect do
        described_class.new(current_user, params).execute(access_requester, **opts)
      end.to change { source.requesters.count }.by(-1)
    end

    it 'returns a <Source>Member' do
      result = described_class.new(current_user, params).execute(access_requester, **opts)

      member = result[:member]
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
      let(:params) { { access_level: access_level_to_assign } }

      it 'returns a ProjectMember with the custom access level' do
        result = described_class.new(current_user, params).execute(access_requester, **opts)

        member = result[:member]

        expect(member.access_level).to eq(access_level_to_assign)
      end
    end
  end

  context 'when an access request is made' do
    before do
      source.request_access(access_requester_user)
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

    context 'when the source is project' do
      let(:source) { project }

      context 'and current user is not a member' do
        it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError'
      end

      context 'and current user is an inherited owner' do
        before do
          source.group.add_owner(current_user)
        end

        it_behaves_like 'a service approving an access request'

        context 'when assigning owner access level' do
          it_behaves_like 'a service approving an access request' do
            let(:access_level_to_assign) { Gitlab::Access::OWNER }
          end
        end
      end

      context 'and current user is a maintainer' do
        before do
          source.add_maintainer(current_user)
        end

        it_behaves_like 'a service approving an access request'

        context 'when assigning owner access level' do
          it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
            let(:access_level_to_assign) { Gitlab::Access::OWNER }
          end
        end

        context 'when assigning planner access level' do
          it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
            let(:access_level_to_assign) { Gitlab::Access::PLANNER }
          end
        end

        context 'when assigning developer access level' do
          it_behaves_like 'a service approving an access request' do
            let(:access_level_to_assign) { Gitlab::Access::DEVELOPER }
          end
        end
      end

      context 'and current user is an owner' do
        before do
          source.add_owner(current_user)
        end

        context 'when assigning owner access level' do
          it_behaves_like 'a service approving an access request' do
            let(:access_level_to_assign) { Gitlab::Access::OWNER }
          end
        end
      end
    end

    context 'when the source is group' do
      let(:source) { group }

      context 'and current user is not a member' do
        it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError'
      end

      context 'and current user is a maintainer' do
        before do
          source.add_maintainer(current_user)
        end

        it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError'
      end

      context 'and current user is an owner' do
        before do
          source.add_owner(current_user)
        end

        context 'when assigning owner access level' do
          it_behaves_like 'a service approving an access request' do
            let(:access_level_to_assign) { Gitlab::Access::OWNER }
          end
        end
      end
    end
  end
end
