# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::Import::SetAsyncJid do
  describe '.set_jid', :clean_gitlab_redis_shared_state do
    let(:project) { create(:project, :import_scheduled) }

    it 'sets the JID in Redis' do
      expect(Gitlab::SidekiqStatus)
        .to receive(:set)
              .with("async-import/#{project.id}", StuckImportJobsWorker::IMPORT_JOBS_EXPIRATION)
              .and_call_original

      described_class.set_jid(project)
    end

    it 'updates the import JID of the project' do
      described_class.set_jid(project)

      expect(project.import_state.reload.jid).to eq("async-import/#{project.id}")
    end
  end
end
