# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectImportState, type: :model, feature_category: :importers do
  let_it_be(:correlation_id) { 'cid' }
  let_it_be(:import_state, refind: true) { create(:import_state, correlation_id_value: correlation_id) }

  subject { import_state }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }

    describe 'checksums attribute' do
      let(:import_state) { build(:import_state, checksums: checksums) }

      before do
        import_state.validate
      end

      context 'when the checksums attribute has invalid fields' do
        let(:checksums) { { fetched: { issue: :foo, note: 20 } } }

        it 'adds errors' do
          expect(import_state.errors.details.keys).to include(:checksums)
        end
      end

      context 'when the checksums attribute has valid fields' do
        let(:checksums) { { fetched: { issue: 8, note: 2 }, imported: { issue: 3, note: 2 } } }

        it 'does not add errors' do
          expect(import_state.errors.details.keys).not_to include(:checksums)
        end
      end
    end
  end

  describe 'Project import job' do
    let_it_be(:project) { create(:project) }

    let(:import_state) { create(:import_state, import_url: generate(:url), project: project) }
    let(:jid) { '551d3ceac5f67a116719ce41' }

    before do
      # Works around https://github.com/rspec/rspec-mocks/issues/910
      allow(Project).to receive(:find).with(project.id).and_return(project)
      allow(project).to receive(:add_import_job).and_return(jid)
    end

    it 'imports a project', :sidekiq_might_not_need_inline do
      expect { import_state.schedule }.to change { import_state.status }.from('none').to('scheduled')
    end

    it 'records job and correlation IDs', :sidekiq_might_not_need_inline do
      allow(Labkit::Correlation::CorrelationId).to receive(:current_or_new_id).and_return(correlation_id)

      import_state.schedule

      expect(project).to have_received(:add_import_job)
      expect(import_state.jid).to eq(jid)
      expect(import_state.correlation_id).to eq(correlation_id)
    end
  end

  describe '#relation_hard_failures' do
    let_it_be(:failures) { create_list(:import_failure, 2, :hard_failure, project: import_state.project, correlation_id_value: correlation_id) }

    it 'returns hard relation failures related to this import' do
      expect(subject.relation_hard_failures(limit: 100)).to match_array(failures)
    end

    it 'limits returned collection to given maximum' do
      expect(subject.relation_hard_failures(limit: 1).size).to eq(1)
    end
  end

  describe '#mark_as_failed' do
    let(:error_message) { 'some message' }

    it 'logs error when update column fails' do
      allow(import_state).to receive(:update_column).and_raise(ActiveRecord::ActiveRecordError)

      expect_next_instance_of(::Import::Framework::Logger) do |logger|
        expect(logger).to receive(:error).with(
          {
            error: 'ActiveRecord::ActiveRecordError',
            message: 'Error setting import status to failed',
            original_error: error_message
          }
        )
      end

      import_state.mark_as_failed(error_message)
    end

    it 'updates last_error with error message' do
      import_state.mark_as_failed(error_message)

      expect(import_state.last_error).to eq(error_message)
    end

    it 'removes project import data' do
      import_data = ProjectImportData.new(data: { 'test' => 'some data' })
      project = create(:project, import_data: import_data)
      import_state = create(:import_state, :started, project: project)

      expect do
        import_state.mark_as_failed(error_message)
      end.to change { project.reload.import_data }.from(import_data).to(nil)
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

  describe '#completed?' do
    it { expect(described_class.new(status: :failed)).to be_completed }
    it { expect(described_class.new(status: :finished)).to be_completed }
    it { expect(described_class.new(status: :canceled)).to be_completed }
    it { expect(described_class.new(status: :scheduled)).not_to be_completed }
    it { expect(described_class.new(status: :started)).not_to be_completed }
  end

  describe '#expire_etag_cache' do
    context 'when project import type has realtime changes endpoint' do
      before do
        import_state.project.import_type = 'github'
      end

      it 'expires revelant etag cache' do
        expect_next_instance_of(Gitlab::EtagCaching::Store) do |instance|
          expect(instance).to receive(:touch).with(Gitlab::Routing.url_helpers.realtime_changes_import_github_path(format: :json))
        end

        subject.expire_etag_cache
      end
    end

    context 'when project import type does not have realtime changes endpoint' do
      before do
        import_state.project.import_type = 'jira'
      end

      it 'does not touch etag caches' do
        expect(Gitlab::EtagCaching::Store).not_to receive(:new)

        subject.expire_etag_cache
      end
    end
  end

  describe 'import state transitions' do
    context 'state transition: [:started] => [:finished]' do
      it 'resets last_error' do
        error_message = 'Some error'
        import_state = create(:import_state, :started, last_error: error_message)

        expect { import_state.finish }.to change { import_state.last_error }.from(error_message).to(nil)
      end

      it 'sets the user mapping feature flag state from import data for other transitions' do
        import_state = create(:import_state, :started)
        import_state.project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: true }).save!

        import_state.finish

        expect(import_state.user_mapping_enabled).to be(true)
      end

      it 'enqueues housekeeping when an import of a fresh project is completed' do
        project = create(:project_empty_repo, :import_started, import_type: :github)

        expect(Projects::AfterImportWorker).to receive(:perform_async).with(project.id)

        project.import_state.finish
      end

      it 'does not perform housekeeping when project repository does not exist' do
        project = create(:project, :import_started, import_type: :github)

        expect(Projects::AfterImportWorker).not_to receive(:perform_async)

        project.import_state.finish
      end

      it 'does not enqueue housekeeping when project does not have a valid import type' do
        project = create(:project, :import_started, import_type: nil)

        expect(Projects::AfterImportWorker).not_to receive(:perform_async)

        project.import_state.finish
      end
    end

    context 'state transition: [:none, :scheduled, :started] => [:canceled]' do
      it 'updates the import status' do
        import_state = create(:import_state, :none)
        expect { import_state.cancel }
          .to change { import_state.status }
          .from('none').to('canceled')
      end

      it 'unsets the JID' do
        import_state = create(:import_state, :started, jid: '123')

        expect(Gitlab::SidekiqStatus)
          .to receive(:unset)
          .with('123')
          .and_call_original

        import_state.cancel!

        expect(import_state.jid).to be_nil
      end

      it 'removes import data' do
        import_data = ProjectImportData.new(data: { 'test' => 'some data' })
        project = create(:project, :import_scheduled, import_data: import_data)

        expect(project)
          .to receive(:remove_import_data)
          .and_call_original

        expect do
          project.import_state.cancel
          project.reload
        end.to change { project.import_data }
          .from(import_data).to(nil)
      end

      it 'sets the user mapping feature flag state from import data for other transitions' do
        import_state = create(:import_state, :scheduled)
        import_state.project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: true }).save!

        import_state.cancel

        expect(import_state.user_mapping_enabled).to be(true)
      end
    end

    context 'state transition: started: [:finished, :canceled, :failed]' do
      using RSpec::Parameterized::TableSyntax

      let_it_be_with_reload(:project) { create(:project) }

      where(
        :import_type,
        :import_status,
        :transition,
        :expected_checksums
      ) do
        'github'         | :started   | :finish  | { 'fetched' => {}, 'imported' => {} }
        'github'         | :started   | :cancel  | { 'fetched' => {}, 'imported' => {} }
        'github'         | :started   | :fail_op | { 'fetched' => {}, 'imported' => {} }
        'github'         | :scheduled | :cancel  | {}
        'gitlab_project' | :started   | :cancel  | {}
      end

      with_them do
        before do
          create(:import_state, status: import_status, import_type: import_type, project: project)
        end

        it 'updates (or does not update) checksums' do
          project.import_state.send(transition)

          expect(project.import_state.checksums).to eq(expected_checksums)
        end
      end
    end
  end

  describe 'completion notification trigger', :aggregate_failures do
    let_it_be_with_reload(:group) { create(:group) }
    let_it_be_with_reload(:project) { create(:project, :import_user_mapping_enabled, namespace: group) }
    let_it_be(:group_owner) { create(:user) }

    let(:user_mapping_enabled) { true }

    subject(:import_state) { create(:import_state, status: initial_status, project: project) }

    before_all do
      group.add_owner(group_owner)
      group.add_owner(project.creator)
    end

    shared_examples 'only the project creator is notified' do |event|
      it 'only sends completion email to the project creator' do
        expect(Notify).to receive(:project_import_complete)
          .with(project.id, project.creator_id, user_mapping_enabled)
          .and_call_original

        import_state.send(:"#{event}!")
      end
    end

    shared_examples 'not a completing event' do |event, initial_status|
      let(:initial_status) { initial_status }

      it 'does not send any completion emails' do
        expect(Notify).not_to receive(:project_import_complete)

        import_state.send(:"#{event}!")
      end
    end

    it_behaves_like 'not a completing event', :schedule, :none
    it_behaves_like 'not a completing event', :force_start, :none
    it_behaves_like 'not a completing event', :start, :scheduled
    it_behaves_like 'not a completing event', :cancel, :started

    context 'when the import state transitions to finished' do
      let(:event) { :finish }
      let(:initial_status) { :started }

      it 'sends a completion email to the project creator and group owners' do
        allow(Notify).to receive(:project_import_complete).and_call_original

        import_state.send(:"#{event}!")

        expect(Notify).to have_received(:project_import_complete).with(project.id, project.creator_id, true)
        expect(Notify).to have_received(:project_import_complete).with(project.id, group_owner.id, true)
      end

      context 'when the project was imported to a personal namespace' do
        let_it_be(:project) { create(:project, :import_user_mapping_enabled) }

        it_behaves_like 'only the project creator is notified', :finish
      end

      context 'when user mapping is disabled' do
        let(:user_mapping_enabled) { false }

        before do
          project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: user_mapping_enabled }).save!
        end

        it_behaves_like 'only the project creator is notified', :finish
      end
    end

    context 'when the import state transitions to failed' do
      let(:initial_status) { :started }

      it_behaves_like 'only the project creator is notified', :fail_op

      context 'when user mapping is disabled' do
        let(:user_mapping_enabled) { false }

        before do
          project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: user_mapping_enabled }).save!
        end

        it_behaves_like 'only the project creator is notified', :fail_op
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

    context 'with a JID' do
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

  describe 'callbacks' do
    context 'after_commit :expire_etag_cache' do
      before do
        import_state.project.import_type = 'github'
      end

      it 'expires etag cache' do
        expect_next_instance_of(Gitlab::EtagCaching::Store) do |instance|
          expect(instance).to receive(:touch).with(Gitlab::Routing.url_helpers.realtime_changes_import_github_path(format: :json))
        end

        subject.save!
      end
    end
  end
end
