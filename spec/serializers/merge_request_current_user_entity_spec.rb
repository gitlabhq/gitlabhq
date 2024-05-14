# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestCurrentUserEntity, feature_category: :code_review_workflow do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:request) { EntityRequest.new(project: project, current_user: user) }

  let(:entity) do
    described_class.new(user, request: request)
  end

  context 'as json' do
    subject { entity.as_json }

    it 'exposes needed attributes' do
      expect(subject).to include(:can_fork, :can_create_merge_request, :fork_path)
    end
  end
end
