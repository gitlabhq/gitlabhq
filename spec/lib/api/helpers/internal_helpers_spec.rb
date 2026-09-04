# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::InternalHelpers, feature_category: :api do
  describe 'log user git operation activity' do
    let_it_be(:project) { create(:project) }
    let(:user) { project.first_owner }
    let(:internal_helper) do
      Class.new { include API::Helpers::InternalHelpers }.new
    end

    before do
      allow(internal_helper).to receive(:project).and_return(project)
    end

    context 'when git pull/fetch/clone action' do
      before do
        allow(internal_helper).to receive(:params).and_return(action: 'git-upload-pack')
      end

      it 'logs the user activity' do
        activity_service = instance_double(::Users::ActivityService)

        args = { author: user, project: project, namespace: project.namespace }

        expect(Users::ActivityService).to receive(:new).with(args).and_return(activity_service)
        expect(activity_service).to receive(:execute)

        internal_helper.log_user_activity(user)
      end

      it 'publishes a user activity event' do
        expect { internal_helper.log_user_activity(user) }
          .to publish_event(Users::ActivityEvent)
          .with({
            user_id: user.id,
            namespace_id: project.root_ancestor.id
          })
      end

      context 'when there is no project' do
        let(:project) { nil }
        let(:user) { build(:user) }

        it 'does not publish a user activity event' do
          expect { internal_helper.log_user_activity(user) }
          .not_to publish_event(Users::ActivityEvent)
        end
      end

      context 'when there is no user' do
        let(:user) { nil }

        it 'does not publish a user activity event' do
          expect { internal_helper.log_user_activity(user) }
          .not_to publish_event(Users::ActivityEvent)
        end
      end
    end
  end

  describe '#set_current_organization_from_repository', feature_category: :organization do
    let(:internal_helper) do
      Class.new do
        include API::Helpers
        include API::Helpers::InternalHelpers
      end.new
    end

    subject(:set_current_organization) { internal_helper.set_current_organization_from_repository }

    before do
      allow(internal_helper).to receive(:project).and_return(project)
    end

    context 'when no project is resolved' do
      let(:project) { nil }

      it 'does not set Current.organization' do
        set_current_organization

        expect(Current.organization_assigned).to be_falsey
      end
    end

    context 'when a project is resolved' do
      let_it_be(:organization) { create(:organization) }
      let_it_be(:project) { create(:project, organization: organization) }

      it 'sets Current.organization to the organization of the project' do
        set_current_organization

        expect(Current.organization).to eq(organization)
        expect(Gitlab::ApplicationContext.current).to include('meta.organization_id' => organization.id)
      end

      context 'when the organization is already assigned' do
        before do
          allow(::Current).to receive_messages(organization_assigned: true, organization: create(:organization))
        end

        it 'does not set Current.organization' do
          expect(::Current).not_to receive(:organization=)

          set_current_organization
        end
      end

      context 'when the organization of the project does not exist' do
        before do
          allow(project).to receive(:organization_id).and_return(non_existing_record_id)
        end

        it 'assigns no organization' do
          set_current_organization

          expect(Current.organization).to be_nil
        end
      end
    end
  end
end
