require 'spec_helper'

describe Members::ApproveAccessRequestService, services: true do
  let(:user) { create(:user) }
  let(:access_requester) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:group) { create(:group, :public) }

  shared_examples 'a service raising ActiveRecord::RecordNotFound' do
    it 'raises ActiveRecord::RecordNotFound' do
      expect { described_class.new(source, user, params).execute }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  shared_examples 'a service raising Gitlab::Access::AccessDeniedError' do
    it 'raises Gitlab::Access::AccessDeniedError' do
      expect { described_class.new(source, user, params).execute }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  shared_examples 'a service approving an access request' do
    it 'succeeds' do
      expect { described_class.new(source, user, params).execute }.to change { source.requesters.count }.by(-1)
    end

    it 'returns a <Source>Member' do
      member = described_class.new(source, user, params).execute

      expect(member).to be_a "#{source.class.to_s}Member".constantize
      expect(member.requested_at).to be_nil
    end

    context 'with a custom access level' do
      let(:params) { { user_id: access_requester.id, access_level: Gitlab::Access::MASTER } }

      it 'returns a ProjectMember with the custom access level' do
        member = described_class.new(source, user, params).execute

        expect(member.access_level).to eq Gitlab::Access::MASTER
      end
    end
  end

  context 'when no access requester are found' do
    let(:params) { { user_id: 42 } }

    it_behaves_like 'a service raising ActiveRecord::RecordNotFound' do
      let(:source) { project }
    end

    it_behaves_like 'a service raising ActiveRecord::RecordNotFound' do
      let(:source) { group }
    end
  end

  context 'when an access requester is found' do
    before do
      project.request_access(access_requester)
      group.request_access(access_requester)
    end
    let(:params) { { user_id: access_requester.id } }

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
        project.team << [user, :master]
        group.add_owner(user)
      end

      it_behaves_like 'a service approving an access request' do
        let(:source) { project }
      end

      it_behaves_like 'a service approving an access request' do
        let(:source) { group }
      end
    end
  end
end
