# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::ReferencedMergeRequestsService, feature_category: :team_planning do
  def create_referencing_mr(attributes = {})
    create(:merge_request, attributes).tap do |merge_request|
      create(:note, :system, project: project, noteable: issue, author: user, note: merge_request.to_reference(full: true))
    end
  end

  def create_closing_mr(attributes = {})
    create_referencing_mr(attributes).tap do |merge_request|
      create(:merge_requests_closing_issues, issue: issue, merge_request: merge_request)
    end
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:other_project) { create(:project, :public, :repository) }
  let_it_be(:issue) { create(:issue, author: user, project: project) }

  let_it_be(:closing_mr) { create_closing_mr(source_project: project) }
  let_it_be(:closing_mr_other_project) { create_closing_mr(source_project: other_project) }

  let_it_be(:referencing_mr) { create_referencing_mr(source_project: project, source_branch: 'csv') }
  let_it_be(:referencing_mr_other_project) { create_referencing_mr(source_project: other_project, source_branch: 'csv') }

  let(:service) { described_class.new(container: project, current_user: user) }

  describe '#execute' do
    it 'returns a list of sorted merge requests' do
      mrs, closed_by_mrs = service.execute(issue)

      expect(mrs).to eq([closing_mr, referencing_mr, closing_mr_other_project, referencing_mr_other_project])
      expect(closed_by_mrs).to eq([closing_mr, closing_mr_other_project])
    end

    context 'performance' do
      it 'does not run extra queries when extra namespaces are included', :use_clean_rails_memory_store_caching do
        service.execute(issue) # warm cache
        control = ActiveRecord::QueryRecorder.new { service.execute(issue) }

        third_project = create(:project, :public)
        create_closing_mr(source_project: third_project)
        service.execute(issue) # warm cache

        expect { service.execute(issue) }.not_to exceed_query_limit(control)
      end

      it 'preloads the head pipeline for each merge request, and its routes' do
        # Hack to ensure no data is preserved on issue before starting the spec,
        # to avoid false negatives
        reloaded_issue = Issue.find(issue.id)

        pipeline_routes = ->(merge_requests) do
          merge_requests.map { |mr| mr.head_pipeline&.project&.full_path }
        end

        closing_mr_other_project.update!(head_pipeline: create(:ci_pipeline))
        control = ActiveRecord::QueryRecorder.new { service.execute(reloaded_issue).each(&pipeline_routes) }

        closing_mr.update!(head_pipeline: create(:ci_pipeline))

        expect { service.execute(issue).each(&pipeline_routes) }
          .not_to exceed_query_limit(control)
      end

      it 'only loads issue notes once' do
        expect(issue).to receive(:notes).once.and_call_original

        service.execute(issue)
      end
    end
  end

  describe '#referenced_merge_requests' do
    it 'returns the referenced merge requests' do
      expect(service.referenced_merge_requests(issue)).to match_array([
        closing_mr,
        closing_mr_other_project,
        referencing_mr,
        referencing_mr_other_project
      ])
    end

    it 'excludes cross project references if the user cannot read cross project' do
      allow(Ability).to receive(:allowed?).and_call_original
      expect(Ability).to receive(:allowed?).with(user, :read_cross_project).at_least(:once).and_return(false)

      expect(service.referenced_merge_requests(issue)).not_to include(closing_mr_other_project)
      expect(service.referenced_merge_requests(issue)).not_to include(referencing_mr_other_project)
    end

    context 'performance' do
      it 'does not run a query for each note author', :use_clean_rails_memory_store_caching do
        service.referenced_merge_requests(issue) # warm cache
        control = ActiveRecord::QueryRecorder.new { service.referenced_merge_requests(issue) }

        create(:note, project: project, noteable: issue, author: create(:user))
        service.referenced_merge_requests(issue) # warm cache

        expect { service.referenced_merge_requests(issue) }.not_to exceed_query_limit(control)
      end
    end
  end

  describe '#closed_by_merge_requests' do
    let(:closed_issue) { build(:issue, :closed, project: project) }

    it 'returns the open merge requests that close this issue' do
      create_closing_mr(source_project: project, state: 'closed')

      expect(service.closed_by_merge_requests(issue)).to match_array([closing_mr, closing_mr_other_project])
    end

    it 'returns an empty array when the current issue is closed already' do
      expect(service.closed_by_merge_requests(closed_issue)).to eq([])
    end

    context 'performance' do
      it 'does not run a query for each note author', :use_clean_rails_memory_store_caching do
        service.closed_by_merge_requests(issue) # warm cache
        control = ActiveRecord::QueryRecorder.new { service.closed_by_merge_requests(issue) }

        create(:note, :system, project: project, noteable: issue, author: create(:user))
        service.closed_by_merge_requests(issue) # warm cache

        expect { service.closed_by_merge_requests(issue) }.not_to exceed_query_limit(control)
      end
    end
  end
end
