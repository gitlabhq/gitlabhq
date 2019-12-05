# frozen_string_literal: true

require 'spec_helper'

describe MergeRequestWidgetEntity do
  include ProjectForksHelper

  let(:project)  { create :project, :repository }
  let(:resource) { create(:merge_request, source_project: project, target_project: project) }
  let(:user)     { create(:user) }

  let(:request) { double('request', current_user: user, project: project) }

  subject do
    described_class.new(resource, request: request).as_json
  end

  describe 'source_project_full_path' do
    it 'includes the full path of the source project' do
      expect(subject[:source_project_full_path]).to be_present
    end

    context 'when the source project is missing' do
      it 'returns `nil` for the source project' do
        resource.allow_broken = true
        resource.update!(source_project: nil)

        expect(subject[:source_project_full_path]).to be_nil
      end
    end
  end

  describe 'issues links' do
    it 'includes issues links when requested' do
      data = described_class.new(resource, request: request, issues_links: true).as_json

      expect(data).to include(:issues_links)
      expect(data[:issues_links]).to include(:assign_to_closing, :closing, :mentioned_but_not_closing)
    end

    it 'omits issue links by default' do
      expect(subject).not_to include(:issues_links)
    end
  end

  it 'has email_patches_path' do
    expect(subject[:email_patches_path])
      .to eq("/#{resource.project.full_path}/merge_requests/#{resource.iid}.patch")
  end

  it 'has plain_diff_path' do
    expect(subject[:plain_diff_path])
      .to eq("/#{resource.project.full_path}/merge_requests/#{resource.iid}.diff")
  end

  describe 'when source project is deleted' do
    let(:project) { create(:project, :repository) }
    let(:forked_project) { fork_project(project) }
    let(:merge_request) { create(:merge_request, source_project: forked_project, target_project: project) }

    it 'returns a blank rebase_path' do
      allow(merge_request).to receive(:should_be_rebased?).and_return(true)
      forked_project.destroy
      merge_request.reload

      entity = described_class.new(merge_request, request: request).as_json

      expect(entity[:rebase_path]).to be_nil
    end
  end
end
