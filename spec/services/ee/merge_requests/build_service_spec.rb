require 'spec_helper'

describe MergeRequests::BuildService do # rubocop:disable RSpec/FilePath
  let(:source_project) { project }
  let(:target_project) { project }
  let(:user) { create(:user) }
  let(:description) { nil }
  let(:source_branch) { 'feature-branch' }
  let(:target_branch) { 'master' }
  let(:merge_request) { service.execute }
  let(:compare) { double(:compare, commits: commits) }
  let(:commit_1) { double(:commit_1, safe_message: "Initial commit\n\nCreate the app") }
  let(:commit_2) { double(:commit_2, safe_message: 'This is a bad commit message!') }
  let(:commits) { nil }

  let(:service) do
    described_class.new(project, user,
                                    description: description,
                                    source_branch: source_branch,
                                    target_branch: target_branch,
                                    source_project: source_project,
                                    target_project: target_project)
  end

  before do
    allow(service).to receive(:branches_valid?) { true }
  end

  context 'project default template configured' do
    let(:template) { "I am the template, you fill me in" }
    let(:project) { create(:empty_project, merge_requests_template: template) }

    context 'issuable default templates feature not available' do
      before do
        stub_licensed_features(issuable_default_templates: false)
      end

      it 'does not set the MR description from template' do
        expect(merge_request.description).not_to eq(template)
      end
    end

    context 'issuable default templates feature available' do
      before do
        stub_licensed_features(issuable_default_templates: true)
      end

      it 'sets the MR description from template' do
        expect(merge_request.description).to eq(template)
      end
    end
  end
end
