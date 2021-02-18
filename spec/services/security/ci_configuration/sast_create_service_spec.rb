# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::CiConfiguration::SastCreateService, :snowplow do
  describe '#execute' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { create(:user) }
    let(:params) { {} }

    subject(:result) { described_class.new(project, user, params).execute }

    context 'user does not belong to project' do
      it 'returns an error status' do
        expect(result[:status]).to eq(:error)
        expect(result[:success_path]).to be_nil
      end

      it 'does not track a snowplow event' do
        subject

        expect_no_snowplow_event
      end
    end

    context 'user belongs to project' do
      before do
        project.add_developer(user)
      end

      it 'does track the snowplow event' do
        subject

        expect_snowplow_event(
          category: 'Security::CiConfiguration::SastCreateService',
          action: 'create',
          label: 'false'
        )
      end

      it 'raises exception if the user does not have permission to create a new branch' do
        allow(project).to receive(:repository).and_raise(Gitlab::Git::PreReceiveError, "You are not allowed to create protected branches on this project.")

        expect { subject }.to raise_error(Gitlab::Git::PreReceiveError)
      end

      context 'with no parameters' do
        it 'returns the path to create a new merge request' do
          expect(result[:status]).to eq(:success)
          expect(result[:success_path]).to match(/#{Gitlab::Routing.url_helpers.project_new_merge_request_url(project, {})}(.*)description(.*)source_branch/)
        end
      end

      context 'with parameters' do
        let(:params) do
          { 'stage' => 'security',
            'SEARCH_MAX_DEPTH' => 1,
            'SECURE_ANALYZERS_PREFIX' => 'new_registry',
            'SAST_EXCLUDED_PATHS' => 'spec,docs' }
        end

        it 'returns the path to create a new merge request' do
          expect(result[:status]).to eq(:success)
          expect(result[:success_path]).to match(/#{Gitlab::Routing.url_helpers.project_new_merge_request_url(project, {})}(.*)description(.*)source_branch/)
        end
      end
    end
  end
end
