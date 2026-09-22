# frozen_string_literal: true

require 'spec_helper'

# Kept in its own file: the shared example rewrites project feature access levels and builds CI job
# token scopes, which leaks into unrelated examples when it shares a file with other endpoint specs.
RSpec.describe 'Work item REST endpoints enforcing job token policies', feature_category: :portfolio_management do
  let_it_be(:project) { create(:project, :repository, :private) }
  let_it_be(:user) { create(:user, developer_of: project) }
  let_it_be(:work_item) { create(:work_item, :issue, project: project) }

  # Only the routes whose legacy issues counterparts accept CI job tokens are enabled.
  describe 'GET list (project scope)' do
    let(:job_token_path) { ->(target) { "/projects/#{target.id}/-/work_items" } }

    it_behaves_like 'a work item endpoint enforcing job token policies'
  end

  describe 'GET show (project scope)' do
    let(:job_token_path) { ->(target) { "/projects/#{target.id}/-/work_items/#{work_item.iid}" } }

    it_behaves_like 'a work item endpoint enforcing job token policies'
  end
end
