# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestSidebarBasicEntity, feature_category: :code_review_workflow do
  let(:project) { create :project, :repository }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
  let(:user) { create(:user) }

  let(:request) { double('request', current_user: user, project: project) }

  let(:entity) { described_class.new(merge_request, request: request).as_json }

  describe '#current_user' do
    it 'contains attributes related to the current user' do
      expect(entity[:current_user].keys).to include(
        :id, :name, :username, :state, :avatar_url, :web_url, :todo,
        :can_edit, :can_move, :can_admin_label, :can_merge
      )
    end
  end
end
