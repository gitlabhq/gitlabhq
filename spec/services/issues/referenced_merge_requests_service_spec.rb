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

  # `freeze: false` is required in this spec: one or more `let_it_be` subjects
  # cannot be frozen by default (deep_freeze traversal failure, a non-AR
  # subject, or an in-memory mutation that survives reload/refind). Do not
  # drop these opt-outs or convert them to `let_it_be_with_reload`/`refind`
  # (see gitlab-org/gitlab#602925).
  let_it_be_with_reload(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :public) }
  let_it_be_with_reload(:other_project) { create(:project, :public) }
  let_it_be_with_reload(:issue) { create(:issue, author: user, project: project) }

  let_it_be(:closing_mr, freeze: false) { create_closing_mr(source_project: project) }
  let_it_be(:closing_mr_other_project, freeze: false) { create_closing_mr(source_project: other_project) }

  let_it_be(:referencing_mr, freeze: false) { create_referencing_mr(source_project: project, source_branch: 'csv') }
  let_it_be(:referencing_mr_other_project, freeze: false) { create_referencing_mr(source_project: other_project, source_branch: 'csv') }

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

  describe '#related_merge_requests' do
    let_it_be(:explicitly_related_mr, freeze: false) do
      create(:merge_request, source_project: project, source_branch: 'improve/awesome').tap do |merge_request|
        create(:merge_requests_closing_issues,
          issue: issue, merge_request: merge_request, link_type: :related, from_mr_description: false)
      end
    end

    it 'returns the referenced and the explicitly related merge requests, sorted by iid' do
      expect(service.related_merge_requests(issue)).to eq([
        closing_mr,
        referencing_mr,
        explicitly_related_mr,
        closing_mr_other_project,
        referencing_mr_other_project
      ])
    end

    it 'includes an explicitly related merge request from another project the user can read' do
      other_project_mr = create(:merge_request, source_project: other_project, source_branch: 'improve/awesome')
      create(:merge_requests_closing_issues,
        issue: issue, merge_request: other_project_mr, link_type: :related, from_mr_description: false)

      expect(service.related_merge_requests(issue)).to include(other_project_mr)
    end

    it 'returns a merge request that is both referenced and explicitly related only once' do
      create(:merge_requests_closing_issues,
        issue: issue, merge_request: referencing_mr, link_type: :related, from_mr_description: false)

      expect(service.related_merge_requests(issue).count(referencing_mr)).to eq(1)
    end

    it 'excludes cross project references if the user cannot read cross project' do
      allow(Ability).to receive(:allowed?).and_call_original
      expect(Ability).to receive(:allowed?).with(user, :read_cross_project).at_least(:once).and_return(false)

      expect(service.related_merge_requests(issue)).not_to include(closing_mr_other_project)
      expect(service.related_merge_requests(issue)).not_to include(referencing_mr_other_project)
    end

    context 'when the explicit_mr_work_item_relations feature flag is disabled' do
      before do
        stub_feature_flags(explicit_mr_work_item_relations: false)
      end

      it 'returns only the referenced merge requests' do
        expect(service.related_merge_requests(issue)).not_to include(explicitly_related_mr)
      end
    end

    context 'performance' do
      it 'does not run extra queries for each explicitly related merge request' do
        service.related_merge_requests(issue) # warm cache
        control = ActiveRecord::QueryRecorder.new { service.related_merge_requests(issue) }

        create(:merge_request, source_project: project, source_branch: 'signed-commits').tap do |merge_request|
          create(:merge_requests_closing_issues,
            issue: issue, merge_request: merge_request, link_type: :related, from_mr_description: false)
        end
        service.related_merge_requests(issue) # warm cache

        expect { service.related_merge_requests(issue) }.not_to exceed_query_limit(control)
      end

      it 'preloads the head pipeline for each merge request, and its routes' do
        # Hack to ensure no data is preserved on issue before starting the spec,
        # to avoid false negatives
        reloaded_issue = Issue.find(issue.id)

        pipeline_routes = ->(merge_requests) do
          merge_requests.map { |mr| mr.head_pipeline&.project&.full_path }
        end

        closing_mr_other_project.update!(head_pipeline: create(:ci_pipeline))
        control = ActiveRecord::QueryRecorder.new { pipeline_routes.call(service.related_merge_requests(reloaded_issue)) }

        explicitly_related_mr.update!(head_pipeline: create(:ci_pipeline))

        expect { pipeline_routes.call(service.related_merge_requests(issue)) }
          .not_to exceed_query_limit(control)
      end
    end
  end

  describe '#related_merge_request_ids' do
    let_it_be(:explicitly_related_mr, freeze: false) do
      create(:merge_request, source_project: project, source_branch: 'improve/awesome').tap do |merge_request|
        create(:merge_requests_closing_issues,
          issue: issue, merge_request: merge_request, link_type: :related, from_mr_description: false)
      end
    end

    it 'returns the ids of the related merge requests' do
      expect(service.related_merge_request_ids(issue))
        .to match_array(service.related_merge_requests(issue).map(&:id))
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
