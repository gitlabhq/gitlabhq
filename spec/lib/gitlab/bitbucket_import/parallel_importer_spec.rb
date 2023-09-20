# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::ParallelImporter, feature_category: :importers do
  subject { described_class }

  it { is_expected.to be_async }

  describe '.track_start_import' do
    it 'tracks the start of import' do
      project = build_stubbed(:project)

      expect_next_instance_of(Gitlab::Import::Metrics, :bitbucket_importer, project) do |metric|
        expect(metric).to receive(:track_start_import)
      end

      subject.track_start_import(project)
    end
  end

  describe '#execute', :clean_gitlab_redis_shared_state do
    let_it_be(:project) { create(:project) }
    let(:importer) { subject.new(project) }

    before do
      create(:import_state, :started, project: project)
    end

    it 'schedules the importing of the repository' do
      expect(Gitlab::BitbucketImport::Stage::ImportRepositoryWorker)
        .to receive_message_chain(:with_status, :perform_async).with(project.id)

      expect(importer.execute).to eq(true)
    end

    it 'sets the JID in Redis' do
      expect(Gitlab::Import::SetAsyncJid).to receive(:set_jid).with(project.import_state).and_call_original

      importer.execute
    end
  end
end
