# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::CiConfiguration::SastCreateService, :snowplow,
  feature_category: :static_application_security_testing do
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

  RSpec.shared_examples_for 'commits directly to the default branch' do
    it 'commits directly to the default branch' do
      expect(project).to receive(:default_branch).twice.and_return('master')

      expect(result.status).to eq(:success)
      expect(result.payload[:success_path]).to match(/#{Gitlab::Routing.url_helpers.project_new_merge_request_url(project, {})}(.*)description(.*)source_branch/)
      expect(result.payload[:branch]).to eq('master')
    end
  end

  context 'when the repository is empty' do
    let_it_be(:project) { create(:project_empty_repo) }

    context 'when initialize_with_sast is false' do
      before do
        project.add_developer(user)
      end

      let(:params) { { initialize_with_sast: false } }

      it 'returns a ServiceResponse error' do
        expect(result).to be_kind_of(ServiceResponse)
        expect(result.status).to eq(:error)
        expect(result.message).to eq('You must <a target="_blank" rel="noopener noreferrer" ' \
                                     'href="http://localhost/help/user/project/repository/_index.md#' \
                                     'add-files-to-a-repository">add at least one file to the ' \
                                     'repository</a> before using Security features.')
      end
    end

    context 'when initialize_with_sast is true' do
      let(:params) { { initialize_with_sast: true } }

      subject(:result) { described_class.new(project, user, params, commit_on_default: true).execute }

      before do
        project.add_maintainer(user)
      end

      it_behaves_like 'commits directly to the default branch'
    end
  end

  context 'when committing to the default branch', :aggregate_failures do
    subject(:result) { described_class.new(project, user, params, commit_on_default: true).execute }

    let(:params) { {} }

    before do
      project.add_developer(user)
    end

    it 'does not try to remove that branch on raised exceptions' do
      expect(Files::MultiService).to receive(:new).and_raise(StandardError, '_exception_')
      expect(project.repository).not_to receive(:rm_branch)

      expect { result }.to raise_error(StandardError, '_exception_')
    end

    it_behaves_like 'commits directly to the default branch'
  end
end
