# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::CreateApprovalEventService, feature_category: :code_review_workflow do
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request) }
  let(:project) { merge_request.project }

  subject(:service) { described_class.new(project: project, current_user: user) }

  describe '#execute' do
    it 'creates approve MR event' do
      expect_next_instance_of(EventCreateService) do |instance|
        expect(instance).to receive(:approve_mr)
          .with(merge_request, user)
      end

      service.execute(merge_request)
    end
  end
end
