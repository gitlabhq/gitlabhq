# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::StopStaleService,
  :clean_gitlab_redis_shared_state,
  :sidekiq_inline,
  feature_category: :continuous_delivery do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:params) { { after: nil } }
  let(:service) { described_class.new(project, user, params) }

  describe '#execute' do
    subject { service.execute }

    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { create(:user) }
    let_it_be(:stale_environment) { create(:environment, project: project, updated_at: 2.weeks.ago) }
    let_it_be(:stale_environment2) { create(:environment, project: project, updated_at: 2.weeks.ago) }
    let_it_be(:recent_environment) { create(:environment, project: project, updated_at: Date.today) }

    let_it_be(:params) { { before: 1.week.ago } }

    before do
      allow(service).to receive(:can?).with(user, :stop_environment, project).and_return(true)
    end

    it 'only stops stale environments' do
      spy_service = Environments::AutoStopWorker.new

      allow(Environments::AutoStopWorker).to receive(:new) { spy_service }

      expect(spy_service).to receive(:perform).with(stale_environment.id).and_call_original
      expect(spy_service).to receive(:perform).with(stale_environment2.id).and_call_original
      expect(spy_service).not_to receive(:perform).with(recent_environment.id)

      expect(Environment).to receive(:deployed_and_updated_before).with(project.id, params[:before]).and_call_original
      expect(Environment).to receive(:without_protected).with(project).and_call_original

      expect(subject.success?).to be_truthy

      expect(stale_environment.reload).to be_stopped
      expect(stale_environment2.reload).to be_stopped
      expect(recent_environment.reload).to be_available
    end
  end
end
