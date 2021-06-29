# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::UsersStarredDashboards::CreateService do
  let_it_be(:user) { create(:user) }

  let(:dashboard_path) { 'config/prometheus/common_metrics.yml' }
  let(:service_instance) { described_class.new(user, project, dashboard_path) }
  let(:project) { create(:project) }
  let(:starred_dashboard_params) do
    {
      user: user,
      project: project,
      dashboard_path: dashboard_path
    }
  end

  shared_examples 'prevented starred dashboard creation' do |message|
    it 'returns error response', :aggregate_failures do
      expect(Metrics::UsersStarredDashboard).not_to receive(:new)

      response = service_instance.execute

      expect(response.status).to be :error
      expect(response.message).to eql message
    end
  end

  describe '.execute' do
    context 'with anonymous user' do
      it_behaves_like 'prevented starred dashboard creation', 'You are not authorized to add star to this dashboard'
    end

    context 'with reporter user' do
      before do
        project.add_reporter(user)
      end

      context 'incorrect dashboard_path' do
        let(:dashboard_path) { 'something_incorrect.yml' }

        it_behaves_like 'prevented starred dashboard creation', 'Dashboard with requested path can not be found'
      end

      context 'with valid dashboard path' do
        it 'creates starred dashboard and returns success response', :aggregate_failures do
          expect_next_instance_of(Metrics::UsersStarredDashboard, starred_dashboard_params) do |starred_dashboard|
            expect(starred_dashboard).to receive(:save).and_return true
          end

          response = service_instance.execute

          expect(response.status).to be :success
        end

        context 'Metrics::UsersStarredDashboard has validation errors' do
          it 'returns error response', :aggregate_failures do
            expect_next_instance_of(Metrics::UsersStarredDashboard, starred_dashboard_params) do |starred_dashboard|
              expect(starred_dashboard).to receive(:save).and_return(false)
              expect(starred_dashboard).to receive(:errors).and_return(double(messages: { base: ['Model validation error'] }))
            end

            response = service_instance.execute

            expect(response.status).to be :error
            expect(response.message).to eql(base: ['Model validation error'])
          end
        end
      end
    end
  end
end
