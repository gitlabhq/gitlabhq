# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::AdvanceStageWorker, feature_category: :importers do
  it_behaves_like Gitlab::Import::AdvanceStage, factory: :import_state

  it 'has a Sidekiq retry of 6' do
    expect(described_class.sidekiq_options['retry']).to eq(6)
  end

  context 'when there are no remaining jobs' do
    let_it_be_with_reload(:project) do
      create(
        :project, :in_group,
        :import_user_mapping_enabled, :user_mapping_to_personal_namespace_owner_enabled,
        import_status: :started, import_jid: '123'
      )
    end

    subject(:worker) { described_class.new }

    before do
      allow(worker)
        .to receive(:wait_for_jobs)
        .with({ '123' => 2 })
        .and_return({})
    end

    it 'enqueues LoadPlaceholderReferencesWorker to save placeholder references' do
      expect(::Import::LoadPlaceholderReferencesWorker).to receive(:perform_async).with(
        ::Import::SOURCE_GITHUB,
        project.import_state.id
      )

      worker.perform(project.id, { '123' => 2 }, 'finish')
    end

    context 'when importing into a personal namespace' do
      before do
        project.update!(namespace: create(:namespace))
      end

      it 'does not enqueue LoadPlaceholderReferencesWorker' do
        expect(::Import::LoadPlaceholderReferencesWorker).not_to receive(:perform_async)

        worker.perform(project.id, { '123' => 2 }, 'finish')
      end

      context 'and user_mapping_to_personal_namespace_owner is disabled' do
        before_all do
          project.build_or_assign_import_data(
            data: { user_mapping_to_personal_namespace_owner_enabled: false }
          ).save!
        end

        it 'enqueues LoadPlaceholderReferencesWorker to save placeholder references' do
          expect(::Import::LoadPlaceholderReferencesWorker).to receive(:perform_async).with(
            ::Import::SOURCE_GITHUB,
            project.import_state.id
          )

          worker.perform(project.id, { '123' => 2 }, 'finish')
        end
      end
    end

    context 'when user contribution mapping is disabled' do
      before do
        allow(Gitlab::GithubImport::Settings).to receive_message_chain(:new, :user_mapping_enabled?).and_return(false)
      end

      it 'does not enqueue LoadPlaceholderReferencesWorker' do
        expect(::Import::LoadPlaceholderReferencesWorker).not_to receive(:perform_async)

        worker.perform(project.id, { '123' => 2 }, 'finish')
      end
    end
  end
end
