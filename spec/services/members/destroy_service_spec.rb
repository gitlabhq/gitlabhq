require 'spec_helper'

describe Members::DestroyService, services: true do
  let(:user) { create(:user) }
  let(:member_user) { create(:user) }
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

  shared_examples 'a service destroying a member' do
    it 'destroys the member' do
      expect { described_class.new(source, user, params).execute }.to change { source.members.count }.by(-1)
    end

    context 'when the given member is an access requester' do
      before do
        source.members.find_by(user_id: member_user).destroy
        source.request_access(member_user)
      end
      let(:access_requester) { source.requesters.find_by(user_id: member_user) }

      it_behaves_like 'a service raising ActiveRecord::RecordNotFound'

      %i[requesters all].each do |scope|
        context "and #{scope} scope is passed" do
          it 'destroys the access requester' do
            expect { described_class.new(source, user, params).execute(scope) }.to change { source.requesters.count }.by(-1)
          end

          it 'calls Member#after_decline_request' do
            expect_any_instance_of(NotificationService).to receive(:decline_access_request).with(access_requester)

            described_class.new(source, user, params).execute(scope)
          end

          context 'when current user is the member' do
            it 'does not call Member#after_decline_request' do
              expect_any_instance_of(NotificationService).not_to receive(:decline_access_request).with(access_requester)

              described_class.new(source, member_user, params).execute(scope)
            end
          end
        end
      end
    end
  end

  context 'when no member are found' do
    let(:params) { { user_id: 42 } }

    it_behaves_like 'a service raising ActiveRecord::RecordNotFound' do
      let(:source) { project }
    end

    it_behaves_like 'a service raising ActiveRecord::RecordNotFound' do
      let(:source) { group }
    end
  end

  context 'when a member is found' do
    before do
      project.team << [member_user, :developer]
      group.add_developer(member_user)
    end
    let(:params) { { user_id: member_user.id } }

    context 'when current user cannot destroy the given member' do
      it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
        let(:source) { project }
      end

      it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
        let(:source) { group }
      end
    end

    context 'when current user can destroy the given member' do
      before do
        project.team << [user, :master]
        group.add_owner(user)
      end

      it_behaves_like 'a service destroying a member' do
        let(:source) { project }
      end

      it_behaves_like 'a service destroying a member' do
        let(:source) { group }
      end
    end
  end
end
