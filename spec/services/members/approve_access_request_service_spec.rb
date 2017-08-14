require 'spec_helper'

describe Members::ApproveAccessRequestService do
  let(:current_user) { create(:user) }
  let(:access_request_user) { create(:user) }
  let(:project) { create(:project, :public, :access_requestable) }
  let(:group) { create(:group, :public, :access_requestable) }
  let(:access_level) { nil }
  let(:opts) { {} }

  shared_examples 'a service raising ActiveRecord::RecordNotFound' do
    it 'raises ActiveRecord::RecordNotFound' do
      expect { described_class.new(source, access_request_user, current_user, access_level).execute(opts) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  shared_examples 'a service raising Gitlab::Access::AccessDeniedError' do
    it 'raises Gitlab::Access::AccessDeniedError' do
      expect { described_class.new(source, access_request_user, current_user, access_level).execute(opts) }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  shared_examples 'a service approving an access request' do
    context 'when access_level is omitted' do
      it 'deletes an AccessRequest' do
        expect { described_class.new(source, access_request_user, current_user).execute(opts) }.to change { source.access_requests.count }.by(-1)
      end

      it 'creates a Member' do
        expect { described_class.new(source, access_request_user, current_user).execute(opts) }.to change { source.members.count }.by(1)
      end

      it 'returns a <Source>Member with the default access level' do
        member = described_class.new(source, access_request_user, current_user).execute(opts)

        expect(member).to be_a "#{source.class}Member".constantize
        expect(member.requested_at).to be_nil
        expect(member.access_level).to eq Gitlab::Access::DEVELOPER
      end
    end

    context 'when access_level is given' do
      let(:access_level) { Gitlab::Access::MASTER }

      it 'deletes an AccessRequest' do
        expect { described_class.new(source, access_request_user, current_user, access_level).execute(opts) }.to change { source.access_requests.count }.by(-1)
      end

      it 'creates a Member' do
        expect { described_class.new(source, access_request_user, current_user, access_level).execute(opts) }.to change { source.members.count }.by(1)
      end

      it 'returns a ProjectMember with the given access level' do
        member = described_class.new(source, access_request_user, current_user, access_level).execute(opts)

        expect(member).to be_a "#{source.class}Member".constantize
        expect(member.requested_at).to be_nil
        expect(member.access_level).to eq Gitlab::Access::MASTER
      end
    end
  end

  context 'when there are no users that have requested access' do
    it_behaves_like 'a service raising ActiveRecord::RecordNotFound' do
      let(:source) { project }
    end

    it_behaves_like 'a service raising ActiveRecord::RecordNotFound' do
      let(:source) { group }
    end
  end

  context 'when users have requested access' do
    before do
      project.request_access(access_request_user)
      group.request_access(access_request_user)
    end

    context 'when current user is nil' do
      let(:current_user) { nil }

      context 'and :force option is not given' do
        it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
          let(:source) { project }
        end

        it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
          let(:source) { group }
        end
      end

      context 'and :force option is false' do
        let(:opts) { { force: false } }

        it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
          let(:source) { project }
        end

        it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
          let(:source) { group }
        end
      end

      context 'and :force option is true' do
        let(:opts) { { force: true } }

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
        project.team << [current_user, :master]
        group.add_owner(current_user)
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
