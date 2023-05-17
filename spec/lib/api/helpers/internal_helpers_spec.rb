# frozen_string_literal: true

require "spec_helper"

RSpec.describe API::Helpers::InternalHelpers, feature_category: :api do
  describe "log user git operation activity" do
    let_it_be(:project) { create(:project) }
    let(:user) { project.first_owner }
    let(:internal_helper) do
      Class.new { include API::Helpers::InternalHelpers }.new
    end

    before do
      allow(internal_helper).to receive(:project).and_return(project)
    end

    shared_examples "handles log git operation activity" do
      it "log the user activity" do
        activity_service = instance_double(::Users::ActivityService)

        args = { author: user, project: project, namespace: project&.namespace }

        expect(Users::ActivityService).to receive(:new).with(args).and_return(activity_service)
        expect(activity_service).to receive(:execute)

        internal_helper.log_user_activity(user)
      end
    end

    context "when git pull/fetch/clone action" do
      before do
        allow(internal_helper).to receive(:params).and_return(action: "git-upload-pack")
      end

      context "with log the user activity" do
        it_behaves_like "handles log git operation activity"
      end
    end

    context "when git push action" do
      before do
        allow(internal_helper).to receive(:params).and_return(action: "git-receive-pack")
      end

      it "does not log the user activity when log_user_git_push_activity is disabled" do
        stub_feature_flags(log_user_git_push_activity: false)

        expect(::Users::ActivityService).not_to receive(:new)

        internal_helper.log_user_activity(user)
      end

      context "with log the user activity when log_user_git_push_activity is enabled" do
        stub_feature_flags(log_user_git_push_activity: true)

        it_behaves_like "handles log git operation activity"
      end
    end
  end
end
