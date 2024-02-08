# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::RefreshImportJidWorker, feature_category: :importers do
  let(:worker) { described_class.new }

  describe '.perform_in_the_future' do
    it 'schedules a job in the future' do
      expect(described_class)
        .to receive(:perform_in)
        .with(5.minutes.to_i, 10, '123')

      described_class.perform_in_the_future(10, '123')
    end
  end

  describe '#perform' do
    let_it_be(:project) { create(:project) }
    let(:import_state) { create(:import_state, project: project, jid: '123abc', status: :started) }

    context 'when the project does not exist' do
      let(:job_args) { [-1, '123'] }

      it_behaves_like 'an idempotent worker'

      it 'does nothing' do
        expect(Gitlab::SidekiqStatus)
          .not_to receive(:expire)

        worker.perform(*job_args)
      end
    end

    context 'when the job is running' do
      let(:job_args) { [project.id, '123'] }

      before do
        allow(Gitlab::SidekiqStatus)
          .to receive(:running?)
          .with('123')
          .and_return(true)
      end

      it_behaves_like 'an idempotent worker'

      it 'refreshes the import JID and reschedules itself' do
        expect(Gitlab::SidekiqStatus)
          .to receive(:expire)
          .with('123', Gitlab::Import::StuckImportJob::IMPORT_JOBS_EXPIRATION)

        expect(Gitlab::SidekiqStatus)
          .to receive(:set)
          .with(import_state.jid, Gitlab::Import::StuckImportJob::IMPORT_JOBS_EXPIRATION)

        expect(worker.class)
          .to receive(:perform_in_the_future)
          .with(project.id, '123')

        worker.perform(*job_args)
      end
    end

    context 'when the job is no longer running' do
      let(:job_args) { [project.id, '123'] }

      before do
        allow(Gitlab::SidekiqStatus)
          .to receive(:running?)
          .with('123')
          .and_return(false)
      end

      it_behaves_like 'an idempotent worker'

      it 'returns' do
        expect(Gitlab::SidekiqStatus)
          .not_to receive(:expire)

        expect(Gitlab::SidekiqStatus)
          .not_to receive(:set)

        worker.perform(*job_args)
      end
    end
  end
end
