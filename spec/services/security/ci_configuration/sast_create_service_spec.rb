# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::CiConfiguration::SastCreateService, :snowplow, feature_category: :sast do
  subject(:result) { described_class.new(project, user, params).execute }

  let(:branch_name) { 'set-sast-config-1' }

  let(:non_empty_params) do
    { 'stage' => 'security',
      'SEARCH_MAX_DEPTH' => 1,
      'SECURE_ANALYZERS_PREFIX' => 'new_registry',
      'SAST_EXCLUDED_PATHS' => 'spec,docs' }
  end

  let(:snowplow_event) do
    {
      category: 'Security::CiConfiguration::SastCreateService',
      action: 'create',
      label: 'false'
    }
  end

  include_examples 'services security ci configuration create service'

  context "when committing to the default branch", :aggregate_failures do
    subject(:result) { described_class.new(project, user, params, commit_on_default: true).execute }

    let(:params) { {} }

    before do
      project.add_developer(user)
    end

    it "doesn't try to remove that branch on raised exceptions" do
      expect(Files::MultiService).to receive(:new).and_raise(StandardError, '_exception_')
      expect(project.repository).not_to receive(:rm_branch)

      expect { result }.to raise_error(StandardError, '_exception_')
    end

    it "commits directly to the default branch" do
      expect(result.status).to eq(:success)
      expect(result.payload[:success_path]).to match(/#{Gitlab::Routing.url_helpers.project_new_merge_request_url(project, {})}(.*)description(.*)source_branch/)
      expect(result.payload[:branch]).to eq('master')
    end
  end
end
