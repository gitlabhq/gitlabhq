# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestForPipelineEntity do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
  let(:request) { EntityRequest.new(project: project) }
  let(:merge_request) { create(:merge_request, target_project: project, source_project: project) }
  let(:presenter) { MergeRequestPresenter.new(merge_request, current_user: user) }

  let(:entity) do
    described_class.new(presenter, request: request)
  end

  before do
    project.add_developer(user)
  end

  context 'as json' do
    subject { entity.as_json }

    it 'exposes needed attributes' do
      expect(subject).to include(
        :iid, :path, :title,
        :source_branch, :source_branch_path,
        :target_branch, :target_branch_path
      )
    end
  end
end
