# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobToken::AutopopulateAllowlistService, feature_category: :secrets_management do
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:accessed_project) { create(:project) }
  let(:service) { described_class.new(accessed_project, maintainer) }
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

  let(:compaction_limit) { 4 }

  before_all do
    accessed_project.add_maintainer(maintainer)
    accessed_project.add_developer(developer)
  end

  before do
    origin_project_namespaces = [
      pns1, pns2, pns3, pns4, pns5, pns6, pns7, pns8
    ]

    origin_project_namespaces.each do |project_namespace|
      create(:ci_job_token_authorization, origin_project: project_namespace.project, accessed_project: accessed_project,
        last_authorized_at: 1.day.ago)
    end

    stub_const("#{described_class.name}::COMPACTION_LIMIT", compaction_limit)
  end

  describe '#execute' do
    context 'with a user with the developer role' do
      let(:service) { described_class.new(accessed_project, developer) }

      it 'raises an access denied error' do
        expect { service.execute }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end

    it 'creates the expected group and project links for the given limit' do
      result = service.execute

      expect(result).to be_success

      expect(Ci::JobToken::GroupScopeLink.autopopulated.pluck(:target_group_id)).to match_array([ns2.id, ns4.id])
      expect(Ci::JobToken::ProjectScopeLink.autopopulated.pluck(:target_project_id)).to match_array([pns1.project.id,
        pns8.project.id])
    end

    context 'with a compaction_limit of 3' do
      let(:compaction_limit) { 3 }

      it 'creates the expected group and project links' do
        result = service.execute

        expect(result).to be_success
        expect(Ci::JobToken::GroupScopeLink.autopopulated.pluck(:target_group_id)).to match_array([ns1.id])
        expect(Ci::JobToken::ProjectScopeLink.autopopulated.pluck(:target_project_id)).to match_array([pns8.project.id])
      end
    end

    context 'with a compaction_limit of 1' do
      let(:compaction_limit) { 1 }

      it 'logs a CompactionLimitCannotBeAchievedError error' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq('Gitlab::Utils::TraversalIdCompactor::CompactionLimitCannotBeAchievedError')

        expect(Ci::JobToken::GroupScopeLink.count).to be(0)
        expect(Ci::JobToken::ProjectScopeLink.count).to be(0)
      end
    end

    context 'when validation fails' do
      let(:compaction_limit) { 5 }

      it 'logs an UnexpectedCompactionEntry error' do
        allow(Gitlab::Utils::TraversalIdCompactor).to receive(:compact).and_wrap_original do |original_method, *args|
          original_response = original_method.call(*args)
          original_response << [1, 2, 3]
        end

        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq('Gitlab::Utils::TraversalIdCompactor::UnexpectedCompactionEntry')
      end

      it 'logs a RedundantCompactionEntry error', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/513211' do
        allow(Gitlab::Utils::TraversalIdCompactor).to receive(:compact).and_wrap_original do |original_method, *args|
          original_response = original_method.call(*args)
          original_response << original_response.last.first(2)
        end

        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq('Gitlab::Utils::TraversalIdCompactor::RedundantCompactionEntry')
      end
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

      context 'with a compaction_limit of 2' do
        let(:compaction_limit) { 2 }

        it 'raises when the limit cannot be achieved' do
          expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
            kind_of(Gitlab::Utils::TraversalIdCompactor::CompactionLimitCannotBeAchievedError),
            { project_id: accessed_project.id, user_id: maintainer.id }
          )
          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq('Gitlab::Utils::TraversalIdCompactor::CompactionLimitCannotBeAchievedError')

          expect(Ci::JobToken::GroupScopeLink.count).to be(0)
          expect(Ci::JobToken::ProjectScopeLink.count).to be(0)
        end
      end

      context 'with a compaction_limit of 3' do
        let(:compaction_limit) { 3 }

        it 'creates creates the expected group and project links' do
          service.execute

          expect(Ci::JobToken::GroupScopeLink.autopopulated.pluck(:target_group_id)).to match_array([ns1.id])
          expect(Ci::JobToken::ProjectScopeLink.autopopulated.pluck(:target_project_id)).to match_array(
            [pns8.project.id, pns9.project.id]
          )
        end
      end
    end
  end
end
