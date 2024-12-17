# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobToken::Authorization, feature_category: :secrets_management do
  let_it_be(:origin_project) { create(:project) }
  let_it_be(:accessed_project) { create(:project) }
  let_it_be(:another_project) { create(:project) }

  describe 'associations' do
    it { is_expected.to belong_to(:origin_project).class_name('Project') }
    it { is_expected.to belong_to(:accessed_project).class_name('Project') }
  end

  describe '.capture', :request_store do
    subject(:capture) do
      described_class.capture(origin_project: origin_project, accessed_project: accessed_project)
    end

    context 'when no authorizations have been captured' do
      it 'captures the authorization in the RequestStore' do
        capture
        expect(described_class.captured_authorizations).to eq(
          origin_project_id: origin_project.id,
          accessed_project_id: accessed_project.id)
      end

      it_behaves_like 'internal event tracking' do
        let(:event) { 'authorize_job_token_with_disabled_scope' }
        let(:project) { accessed_project }
        let(:category) { described_class }
        let(:label) { 'cross-project' }
      end

      context 'when origin project is the same as the accessed project' do
        let(:accessed_project) { origin_project }

        it 'does not capture the authorization' do
          capture
          expect(described_class.captured_authorizations).to be_nil
        end

        it_behaves_like 'internal event tracking' do
          let(:event) { 'authorize_job_token_with_disabled_scope' }
          let(:project) { accessed_project }
          let(:category) { described_class }
          let(:label) { 'same-project' }
        end
      end
    end
  end

  describe '.log_captures_async', :request_store do
    subject(:log_captures_async) do
      described_class.log_captures_async
    end

    shared_examples 'does not log the authorization' do
      it 'does not schedule the worker' do
        expect(Ci::JobToken::LogAuthorizationWorker).not_to receive(:perform_in)

        log_captures_async
      end
    end

    context 'when authorizations have been captured during the request' do
      before do
        described_class.capture(
          origin_project: origin_project,
          accessed_project: accessed_project)
      end

      context 'when authorization is cross project' do
        it 'schedules the log' do
          expect(::Ci::JobToken::LogAuthorizationWorker)
            .to receive(:perform_in).with(5.minutes, accessed_project.id, origin_project.id)

          log_captures_async
        end
      end

      context 'when authorization is self-referential' do
        let(:accessed_project) { origin_project }

        it_behaves_like 'does not log the authorization'
      end
    end

    context 'when authorizations have not been captured during the request' do
      it_behaves_like 'does not log the authorization'
    end
  end

  describe '.log_captures!' do
    subject(:log_captures) do
      described_class.log_captures!(origin_project_id: origin_project.id, accessed_project_id: accessed_project.id)
    end

    context 'when authorization does not exist in the database' do
      it 'creates a new authorization' do
        expect { log_captures }.to change { described_class.count }.by(1)

        expect(described_class.last).to have_attributes(
          origin_project: origin_project,
          accessed_project: accessed_project)
      end
    end

    context 'when authorization for the same projects already exists in the database' do
      let!(:existing_authorization) do
        create(:ci_job_token_authorization,
          origin_project: origin_project,
          accessed_project: accessed_project,
          last_authorized_at: 1.day.ago)
      end

      it 'updates the timestamp instead of creating a new record' do
        expect { log_captures }
          .to change { existing_authorization.reload.last_authorized_at }
          .and not_change { described_class.count }
      end
    end
  end

  describe '.preload_origin_project' do
    before do
      create_list(:ci_job_token_authorization, 5)
    end

    it 'does not perform N+1 queries' do
      control = ActiveRecord::QueryRecorder.new do
        described_class.preload_origin_project.map { |a| a.origin_project.full_path }
      end

      create(:ci_job_token_authorization)

      expect do
        described_class.preload_origin_project.map { |a| a.origin_project.full_path }
      end.not_to exceed_query_limit(control)
    end
  end

  describe '.for_project scope' do
    let(:project) { create(:project) }

    let!(:current_authorizations) do
      create_list(:ci_job_token_authorization, 2, accessed_project: project)
    end

    let!(:other_authorization) { create(:ci_job_token_authorization) }

    it 'contains only the authorizations targeting the project' do
      authorizations = described_class.for_project(project)
      expect(authorizations).to eq(current_authorizations)

      expect(authorizations).not_to include(other_authorization)
    end
  end
end
