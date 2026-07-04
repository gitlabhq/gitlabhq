# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Mergeability::CheckCodeOwnersApprovalService,
  feature_category: :code_review_workflow do
  subject(:check) { described_class.new(merge_request: merge_request, params: params) }

  let_it_be(:project)       { create(:project, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  let(:params) { {} }

  it_behaves_like 'mergeability check service',
    :code_owners_approval,
    'Checks whether required CODEOWNERS have approved'

  describe '#skip?' do
    it 'is false by default' do
      expect(check.skip?).to be(false)
    end

    it 'is true when skip_code_owners_check param is set' do
      check = described_class.new(merge_request: merge_request, params: { skip_code_owners_check: true })
      expect(check.skip?).to be(true)
    end
  end

  describe '#cacheable?' do
    it { expect(check.cacheable?).to be(false) }
  end

  describe '#execute' do
    let(:codeowners_content) { nil }
    let(:approved_users)     { [] }

    before do
      blob = codeowners_content ? instance_double(Blob, data: codeowners_content) : nil

      allow(project.repository).to receive(:blob_at_branch).and_return(nil)
      allow(project.repository)
        .to receive(:blob_at_branch).with(merge_request.target_branch, 'CODEOWNERS')
        .and_return(blob)

      allow(merge_request).to receive(:modified_paths).and_return(['app/models/user.rb'])
      allow(merge_request).to receive(:approved_by_users).and_return(approved_users)
    end

    context 'when no CODEOWNERS file exists' do
      let(:codeowners_content) { nil }

      it 'returns inactive' do
        result = check.execute
        expect(result.status).to eq(Gitlab::MergeRequests::Mergeability::CheckResult::INACTIVE_STATUS)
      end
    end

    context 'when CODEOWNERS file exists but no rule matches changed files' do
      let(:codeowners_content) { "*.vue @frontend\n" }

      it 'returns success (no required owners)' do
        result = check.execute
        expect(result.status).to eq(Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS)
      end
    end

    context 'when a rule matches and approval is missing' do
      let(:codeowners_content) { "*.rb @backend\n" }

      it 'returns failure' do
        result = check.execute
        expect(result.status).to eq(Gitlab::MergeRequests::Mergeability::CheckResult::FAILED_STATUS)
        expect(result.payload[:missing_owners]).to eq(['@backend'])
      end
    end

    context 'when a rule matches and the required owner has approved' do
      let(:codeowners_content) { "*.rb @backend\n" }
      let(:approved_users)     { [build_stubbed(:user, username: 'backend')] }

      it 'returns success' do
        result = check.execute
        expect(result.status).to eq(Gitlab::MergeRequests::Mergeability::CheckResult::SUCCESS_STATUS)
      end
    end
  end
end
