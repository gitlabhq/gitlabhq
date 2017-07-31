require 'spec_helper'

describe Members::DestroyAccessRequestService do
  subject { described_class.new(source, access_requester, current_user).execute }

  let(:access_requester) { create(:user) }
  let(:other_user) { create(:user) }
  let(:project) { create(:project, :public, :access_requestable) }
  let(:group) { create(:group, :public, :access_requestable) }

  shared_examples 'a service raising ActiveRecord::RecordNotFound' do
    it 'raises ActiveRecord::RecordNotFound' do
      expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  shared_examples 'a service raising Gitlab::Access::AccessDeniedError' do
    it 'raises Gitlab::Access::AccessDeniedError' do
      expect { subject }.to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  shared_examples 'a service destroying an access request' do
    context 'when the given user did not request access' do
      let(:current_user) { access_requester }

      it_behaves_like 'a service raising ActiveRecord::RecordNotFound'
    end

    context 'when the given user requested access' do
      let!(:access_request) { source.request_access(access_requester) }

      context 'when current_user is the user requesting access' do
        let(:current_user) { access_requester }

        it 'destroys the access request' do
          expect { subject }.to change { source.access_requests.count }.by(-1)
        end

        it 'does not send a decline_access_request notification' do
          expect_any_instance_of(NotificationService).not_to receive(:decline_access_request)

          subject
        end
      end

      context 'when current_user is not the user requesting access' do
        let(:current_user) { other_user }

        context 'when current_user can decline the access request' do
          before do
            project.team << [current_user, :master]
            group.add_owner(current_user)
          end

          it 'destroys the access request' do
            expect { subject }.to change { source.access_requests.count }.by(-1)
          end

          it 'sends a decline_access_request notification' do
            expect_any_instance_of(NotificationService).to receive(:decline_access_request)

            subject
          end
        end

        context 'when current_user cannot decline the access request' do
          it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError'
        end
      end
    end
  end

  it_behaves_like 'a service destroying an access request' do
    let(:source) { project }
  end

  it_behaves_like 'a service destroying an access request' do
    let(:source) { group }
  end
end
