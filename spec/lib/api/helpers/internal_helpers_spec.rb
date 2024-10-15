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
end
