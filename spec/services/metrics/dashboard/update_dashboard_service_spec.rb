# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::Dashboard::UpdateDashboardService, :use_clean_rails_memory_store_caching do
  include MetricsDashboardHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:environment) { create(:environment, project: project) }

  describe '#execute' do
    subject(:service_call) { described_class.new(project, user, params).execute }

    let(:commit_message) { 'test' }
    let(:branch) { 'dashboard_new_branch' }
    let(:dashboard) { 'config/prometheus/common_metrics.yml' }
    let(:file_name) { 'custom_dashboard.yml' }
    let(:file_content_hash) { YAML.safe_load(File.read(dashboard)) }
    let(:params) do
      {
        file_name: file_name,
        file_content: file_content_hash,
        commit_message: commit_message,
        branch: branch
      }
    end

    context 'user does not have push right to repository' do
      it_behaves_like 'misconfigured dashboard service response with stepable', :forbidden, 'You are not allowed to push into this branch. Create another branch or open a merge request.'
    end

    context 'with rights to push to the repository' do
      before do
        project.add_maintainer(user)
      end

      context 'path traversal attack attempt' do
        context 'with a yml extension' do
          let(:file_name) { 'config/prometheus/../database.yml' }

          it_behaves_like 'misconfigured dashboard service response with stepable', :bad_request, "A file with this name doesn't exist"
        end

        context 'without a yml extension' do
          let(:file_name) { '../../..../etc/passwd' }

          it_behaves_like 'misconfigured dashboard service response with stepable', :bad_request, 'The file name should have a .yml extension'
        end
      end

      context 'valid parameters' do
        it_behaves_like 'valid dashboard update process'
      end

      context 'selected branch already exists' do
        let(:branch) { 'existing_branch' }

        before do
          project.repository.add_branch(user, branch, 'master')
        end

        it_behaves_like 'misconfigured dashboard service response with stepable', :bad_request, 'There was an error updating the dashboard, branch named: existing_branch already exists.'
      end

      context 'Files::UpdateService success' do
        let(:merge_request) { project.merge_requests.last }

        before do
          allow(::Files::UpdateService).to receive(:new).and_return(double(execute: { status: :success }))
        end

        it 'returns success', :aggregate_failures do
          dashboard_details = {
            path: '.gitlab/dashboards/custom_dashboard.yml',
            display_name: 'custom_dashboard.yml',
            default: false,
            system_dashboard: false
          }

          expect(service_call[:status]).to be :success
          expect(service_call[:http_status]).to be :created
          expect(service_call[:dashboard]).to match dashboard_details
          expect(service_call[:merge_request]).to eq(Gitlab::UrlBuilder.build(merge_request))
        end

        context 'when the merge request does not succeed' do
          let(:error_message) { 'There was an error' }

          let(:merge_request) do
            build(:merge_request, target_project: project, source_project: project, author: user)
          end

          before do
            merge_request.errors.add(:base, error_message)
            allow_next_instance_of(::MergeRequests::CreateService) do |mr|
              allow(mr).to receive(:execute).and_return(merge_request)
            end
          end

          it 'returns an appropriate message and status code', :aggregate_failures do
            result = service_call

            expect(result.keys).to contain_exactly(:message, :http_status, :status, :last_step)
            expect(result[:status]).to eq(:error)
            expect(result[:http_status]).to eq(:bad_request)
            expect(result[:message]).to eq(error_message)
          end
        end

        context 'with escaped characters in file name' do
          let(:file_name) { "custom_dashboard%26copy.yml" }

          it 'escapes the special characters', :aggregate_failures do
            dashboard_details = {
              path: '.gitlab/dashboards/custom_dashboard&copy.yml',
              display_name: 'custom_dashboard&copy.yml',
              default: false,
              system_dashboard: false
            }

            expect(service_call[:status]).to be :success
            expect(service_call[:http_status]).to be :created
            expect(service_call[:dashboard]).to match dashboard_details
          end
        end

        context 'when pushing to the default branch' do
          let(:branch) { 'master' }

          it 'does not create a merge request', :aggregate_failures do
            dashboard_details = {
              path: '.gitlab/dashboards/custom_dashboard.yml',
              display_name: 'custom_dashboard.yml',
              default: false,
              system_dashboard: false
            }

            expect(::MergeRequests::CreateService).not_to receive(:new)
            expect(service_call.keys).to contain_exactly(:dashboard, :http_status, :status)
            expect(service_call[:status]).to be :success
            expect(service_call[:http_status]).to be :created
            expect(service_call[:dashboard]).to match dashboard_details
          end
        end
      end

      context 'Files::UpdateService fails' do
        before do
          allow(::Files::UpdateService).to receive(:new).and_return(double(execute: { status: :error }))
        end

        it 'returns error' do
          expect(service_call[:status]).to be :error
        end
      end
    end
  end
end
