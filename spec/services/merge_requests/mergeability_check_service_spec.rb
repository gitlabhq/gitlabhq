# frozen_string_literal: true

require 'spec_helper'

describe MergeRequests::MergeabilityCheckService do
  shared_examples_for 'unmergeable merge request' do
    it 'updates or keeps merge status as cannot_be_merged' do
      subject

      expect(merge_request.merge_status).to eq('cannot_be_merged')
    end

    it 'does not change the merge ref HEAD' do
      expect { subject }.not_to change(merge_request, :merge_ref_head)
    end

    it 'returns ServiceResponse.error' do
      result = subject

      expect(result).to be_a(ServiceResponse)
      expect(result).to be_error
    end
  end

  shared_examples_for 'mergeable merge request' do
    it 'updates or keeps merge status as can_be_merged' do
      subject

      expect(merge_request.merge_status).to eq('can_be_merged')
    end

    it 'updates the merge ref' do
      expect { subject }.to change(merge_request, :merge_ref_head).from(nil)
    end

    it 'returns ServiceResponse.success' do
      result = subject

      expect(result).to be_a(ServiceResponse)
      expect(result).to be_success
    end
  end

  describe '#execute' do
    let(:project) { create(:project, :repository) }
    let(:merge_request) { create(:merge_request, merge_status: :unchecked, source_project: project, target_project: project) }
    let(:repo) { project.repository }

    subject { described_class.new(merge_request).execute }

    before do
      project.add_developer(merge_request.author)
    end

    it_behaves_like 'mergeable merge request'

    context 'when broken' do
      before do
        allow(merge_request).to receive(:broken?) { true }
        allow(project.repository).to receive(:can_be_merged?) { false }
      end

      it_behaves_like 'unmergeable merge request'
    end

    context 'when it has conflicts' do
      before do
        allow(merge_request).to receive(:broken?) { false }
        allow(project.repository).to receive(:can_be_merged?) { false }
      end

      it_behaves_like 'unmergeable merge request'
    end

    context 'when MR cannot be merged and has no merge ref' do
      before do
        merge_request.mark_as_unmergeable!
      end

      it_behaves_like 'unmergeable merge request'
    end

    context 'when MR cannot be merged and has outdated merge ref' do
      before do
        MergeRequests::MergeToRefService.new(project, merge_request.author).execute(merge_request)
        merge_request.mark_as_unmergeable!
      end

      it_behaves_like 'unmergeable merge request'
    end
  end
end
