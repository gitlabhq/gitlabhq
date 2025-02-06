# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobToken::AuthorizationsCompactor, feature_category: :secrets_management do
  let_it_be(:accessed_project) { create(:project) }
  let(:excluded_namespace_paths) { [] }
  let(:compactor) { described_class.new(accessed_project.id) }

  # [1, 21],            ns1, p1
  # [1, 2, 3],          ns1, ns2, p2
  # [1, 2, 4],          ns1, ns2, p3
  # [1, 2, 5],          ns1, ns2, p4
  # [1, 2, 12, 13],     ns1, ns2, ns3, p5
  # [1, 6, 7],          ns1, ns4, p6
  # [1, 6, 8],          ns1, ns4, p7
  # [9, 10, 11]         ns5, ns6, p8

  let_it_be(:ns1) { create(:group, name: 'ns1') }
  let_it_be(:ns2) { create(:group, parent: ns1, name: 'ns2') }
  let_it_be(:ns3) { create(:group, parent: ns2, name: 'ns3') }
  let_it_be(:ns4) { create(:group, parent: ns1, name: 'ns4') }
  let_it_be(:ns5) { create(:group, name: 'ns5') }
  let_it_be(:ns6) { create(:group, parent: ns5, name: 'ns6') }

  let_it_be(:pns1) { create(:project_namespace, parent: ns1) }
  let_it_be(:pns2) { create(:project_namespace, parent: ns2) }
  let_it_be(:pns3) { create(:project_namespace, parent: ns2) }
  let_it_be(:pns4) { create(:project_namespace, parent: ns2) }
  let_it_be(:pns5) { create(:project_namespace, parent: ns3) }
  let_it_be(:pns6) { create(:project_namespace, parent: ns4) }
  let_it_be(:pns7) { create(:project_namespace, parent: ns4) }
  let_it_be(:pns8) { create(:project_namespace, parent: ns6) }

  before do
    origin_project_namespaces = [
      pns1, pns2, pns3, pns4, pns5, pns6, pns7, pns8
    ]

    origin_project_namespaces.each do |project_namespace|
      create(:ci_job_token_authorization, origin_project: project_namespace.project, accessed_project: accessed_project,
        last_authorized_at: 1.day.ago)
    end
  end

  describe '#compact' do
    it 'compacts the allowlist groups and projects as expected for the given limit' do
      compactor.compact(4)

      expect(compactor.allowlist_groups).to match_array([ns2, ns4])
      expect(compactor.allowlist_projects).to match_array([pns1.project, pns8.project])
    end

    it 'compacts the allowlist groups and projects as expected for the given limit' do
      compactor.compact(3)

      expect(compactor.allowlist_groups).to match_array([ns1])
      expect(compactor.allowlist_projects).to match_array([pns8.project])
    end

    it 'raises when the limit cannot be achieved' do
      expect do
        compactor.compact(1)
      end.to raise_error(Gitlab::Utils::TraversalIdCompactor::CompactionLimitCannotBeAchievedError)
    end

    it 'raises when an unexpected compaction entry is found' do
      allow(Gitlab::Utils::TraversalIdCompactor).to receive(:compact).and_wrap_original do |original_method, *args|
        original_response = original_method.call(*args)
        original_response << [1, 2, 3]
      end

      expect { compactor.compact(5) }.to raise_error(Gitlab::Utils::TraversalIdCompactor::UnexpectedCompactionEntry)
    end

    it 'raises when a redundant compaction entry is found' do
      allow(Gitlab::Utils::TraversalIdCompactor).to receive(:compact).and_wrap_original do |original_method, *args|
        original_response = original_method.call(*args)
        last_item = original_response.last
        original_response << (last_item.size > 1 ? last_item[0...-1] : last_item)
      end

      expect { compactor.compact(5) }.to raise_error(Gitlab::Utils::TraversalIdCompactor::RedundantCompactionEntry)
    end

    context 'with three top-level namespaces' do
      # [1, 21],            ns1, p1
      # [1, 2, 3],          ns1, ns2, p2
      # [1, 2, 4],          ns1, ns2, p3
      # [1, 2, 5],          ns1, ns2, p4
      # [1, 2, 12, 13],     ns1, ns2, ns3, p5
      # [1, 6, 7],          ns1, ns4, p6
      # [1, 6, 8],          ns1, ns4, p7
      # [9, 10, 11]         ns5, ns6, p8
      # [14, 15]            ns7, p9
      let(:ns7) { create(:group, name: 'ns7') }
      let(:pns9) { create(:project_namespace, parent: ns7) }

      before do
        create(:ci_job_token_authorization, origin_project: pns9.project, accessed_project: accessed_project,
          last_authorized_at: 1.day.ago)
      end

      it 'raises when the limit cannot be achieved' do
        expect do
          compactor.compact(2)
        end.to raise_error(Gitlab::Utils::TraversalIdCompactor::CompactionLimitCannotBeAchievedError)
      end

      it 'does not raise when the limit cannot be achieved' do
        expect do
          compactor.compact(3)
        end.not_to raise_error
      end
    end

    context 'with exiting group scope links' do
      describe 'when a single group exists' do
        before do
          create(:ci_job_token_group_scope_link, source_project: accessed_project, target_group: ns6)
        end

        it 'removes it from the compaction process' do
          compactor.compact(4)

          expect(compactor.allowlist_groups).to match_array([ns2, ns4])
          expect(compactor.allowlist_projects).to match_array([pns1.project])
        end
      end

      describe 'when a multiple groups exist' do
        before do
          create(:ci_job_token_group_scope_link, source_project: accessed_project, target_group: ns6)
          create(:ci_job_token_group_scope_link, source_project: accessed_project, target_group: ns2)
        end

        it 'removes it from the compaction process' do
          compactor.compact(4)

          expect(compactor.allowlist_groups).to match_array([ns4])
          expect(compactor.allowlist_projects).to match_array([pns1.project])
        end
      end
    end
  end

  context 'with exiting project scope links' do
    describe 'when a single project exists' do
      before do
        create(:ci_job_token_project_scope_link, source_project: accessed_project, direction: :inbound,
          target_project: pns8.project)
      end

      it 'removes it from the compaction process' do
        compactor.compact(4)

        expect(compactor.allowlist_groups).to match_array([ns2, ns4])
        expect(compactor.allowlist_projects).to match_array([pns1.project])
      end
    end

    describe 'when a multiple projects exist' do
      before do
        create(:ci_job_token_project_scope_link, source_project: accessed_project, direction: :inbound,
          target_project: pns8.project)
        create(:ci_job_token_project_scope_link, source_project: accessed_project, direction: :inbound,
          target_project: pns2.project)
      end

      it 'removes it from the compaction process' do
        compactor.compact(6)

        expect(compactor.allowlist_groups).to match_array([ns2, ns4])
        expect(compactor.allowlist_projects).to match_array([pns1.project])
      end
    end
  end

  context 'with exiting group and project scope links' do
    before do
      create(:ci_job_token_group_scope_link, source_project: accessed_project, target_group: ns2)
      create(:ci_job_token_project_scope_link, source_project: accessed_project, direction: :inbound,
        target_project: pns8.project)
    end

    it 'removes it from the compaction process' do
      compactor.compact(4)

      expect(compactor.allowlist_groups).to match_array([ns4])
      expect(compactor.allowlist_projects).to match_array([pns1.project])
    end
  end

  describe '#origin_traversal_ids' do
    it 'does not cause N+1 queries when loading projects' do
      accessed_project_control = create(:project)
      create(:ci_job_token_authorization, origin_project: pns1.project, accessed_project: accessed_project_control,
        last_authorized_at: 1.day.ago)
      compactor_control = described_class.new(accessed_project_control.id)
      control = ActiveRecord::QueryRecorder.new do
        compactor_control.origin_project_traversal_ids
      end

      expect { compactor.origin_project_traversal_ids }.not_to exceed_query_limit(control)
    end
  end
end
