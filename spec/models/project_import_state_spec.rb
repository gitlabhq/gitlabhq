# frozen_string_literal: true

require 'spec_helper'

describe ProjectImportState, type: :model do
  subject { create(:import_state) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
  end

  describe 'Project import job' do
    let(:import_state) { create(:import_state, import_url: generate(:url)) }
    let(:project) { import_state.project }

    before do
      allow_any_instance_of(Gitlab::GitalyClient::RepositoryService).to receive(:import_repository)
        .with(project.import_url).and_return(true)

      # Works around https://github.com/rspec/rspec-mocks/issues/910
      allow(Project).to receive(:find).with(project.id).and_return(project)
      expect(project.repository).to receive(:after_import).and_call_original
      expect(project.wiki.repository).to receive(:after_import).and_call_original
    end

    it 'imports a project', :sidekiq_might_not_need_inline do
      expect(RepositoryImportWorker).to receive(:perform_async).and_call_original

      expect { import_state.schedule }.to change { import_state.jid }
      expect(import_state.status).to eq('finished')
    end
  end

  describe '#human_status_name' do
    context 'when import_state exists' do
      it 'returns the humanized status name' do
        import_state = build(:import_state, :started)

        expect(import_state.human_status_name).to eq("started")
      end
    end
  end

  describe 'import state transitions' do
    context 'state transition: [:started] => [:finished]' do
      let(:after_import_service) { spy(:after_import_service) }
      let(:housekeeping_service) { spy(:housekeeping_service) }

      before do
        allow(Projects::AfterImportService)
          .to receive(:new) { after_import_service }

        allow(after_import_service)
          .to receive(:execute) { housekeeping_service.execute }

        allow(Projects::HousekeepingService)
          .to receive(:new) { housekeeping_service }
      end

      it 'resets last_error' do
        error_message = 'Some error'
        import_state = create(:import_state, :started, last_error: error_message)

        expect { import_state.finish }.to change { import_state.last_error }.from(error_message).to(nil)
      end

      it 'performs housekeeping when an import of a fresh project is completed' do
        project = create(:project_empty_repo, :import_started, import_type: :github)

        project.import_state.finish

        expect(after_import_service).to have_received(:execute)
        expect(housekeeping_service).to have_received(:execute)
      end

      it 'does not perform housekeeping when project repository does not exist' do
        project = create(:project, :import_started, import_type: :github)

        project.import_state.finish

        expect(housekeeping_service).not_to have_received(:execute)
      end

      it 'does not perform housekeeping when project does not have a valid import type' do
        project = create(:project, :import_started, import_type: nil)

        project.import_state.finish

        expect(housekeeping_service).not_to have_received(:execute)
      end
    end
  end

  describe 'clearing `jid` after finish', :clean_gitlab_redis_cache do
    context 'without an JID' do
      it 'does nothing' do
        import_state = create(:import_state, :started)

        expect(Gitlab::SidekiqStatus)
          .not_to receive(:unset)

        import_state.finish!
      end
    end

    context 'with an JID' do
      it 'unsets the JID' do
        import_state = create(:import_state, :started, jid: '123')

        expect(Gitlab::SidekiqStatus)
          .to receive(:unset)
          .with('123')
          .and_call_original

        import_state.finish!

        expect(import_state.jid).to be_nil
      end
    end
  end
end
