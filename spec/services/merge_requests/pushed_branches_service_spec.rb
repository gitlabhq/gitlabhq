# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::PushedBranchesService, feature_category: :source_code_management do
  let(:project) { create(:project) }
  let!(:service) { described_class.new(project: project, current_user: nil, params: { changes: pushed_branches }) }

  context 'when branches pushed' do
    let(:pushed_branches) do
      %w[branch1 branch2 closed-branch1 closed-branch2 extra1 extra2].map do |branch|
        { ref: "refs/heads/#{branch}" }
      end
    end

    it 'returns only branches which have a open and closed merge request' do
      create(:merge_request, source_branch: 'branch1', source_project: project)
      create(:merge_request, source_branch: 'branch2', source_project: project)
      create(:merge_request, target_branch: 'branch2', source_project: project)
      create(:merge_request, :closed, target_branch: 'closed-branch1', source_project: project)
      create(:merge_request, :closed, source_branch: 'closed-branch2', source_project: project)
      create(:merge_request, source_branch: 'extra1')

      expect(service.execute).to contain_exactly(
        'branch1',
        'branch2',
        'closed-branch2'
      )
    end
  end

  context 'when tags pushed' do
    let(:pushed_branches) do
      %w[v10.0.0 v11.0.2 v12.1.0].map do |branch|
        { ref: "refs/tags/#{branch}" }
      end
    end

    it 'returns empty result without any SQL query performed' do
      control = ActiveRecord::QueryRecorder.new do
        expect(service.execute).to be_empty
      end

      expect(control.count).to be_zero
    end
  end
end
