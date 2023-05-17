# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRepository, :aggregate_failures, feature_category: :container_registry do
  using RSpec::Parameterized::TableSyntax

  let(:group) { create(:group, name: 'group') }
  let(:project) { create(:project, path: 'test', group: group) }

  let(:repository) do
    create(:container_repository, name: 'my_image', project: project)
  end

  before do
    stub_container_registry_config(
      enabled: true, api_url: 'http://registry.gitlab', host_port: 'registry.gitlab'
    )

    stub_request(:get, "http://registry.gitlab/v2/group/test/my_image/tags/list?n=#{::ContainerRegistry::Client::DEFAULT_TAGS_PAGE_SIZE}")
      .with(headers: { 'Accept' => ContainerRegistry::Client::ACCEPTED_TYPES.join(', ') })
      .to_return(
        status: 200,
        body: Gitlab::Json.dump(tags: ['test_tag']),
        headers: { 'Content-Type' => 'application/json' })
  end

  it_behaves_like 'having unique enum values'

  describe 'associations' do
    it 'belongs to the project' do
      expect(repository).to belong_to(:project)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:migration_retries_count) }
    it { is_expected.to validate_numericality_of(:migration_retries_count).is_greater_than_or_equal_to(0) }

    it { is_expected.to validate_inclusion_of(:migration_aborted_in_state).in_array(described_class::ABORTABLE_MIGRATION_STATES) }
    it { is_expected.to allow_value(nil).for(:migration_aborted_in_state) }

    context 'migration_state' do
      it { is_expected.to validate_presence_of(:migration_state) }
      it { is_expected.to validate_inclusion_of(:migration_state).in_array(described_class::MIGRATION_STATES) }

      describe 'pre_importing' do
        it 'validates expected attributes' do
          expect(build(:container_repository, migration_state: 'pre_importing')).to be_invalid
          expect(build(:container_repository, :pre_importing)).to be_valid
        end
      end

      describe 'pre_import_done' do
        it 'validates expected attributes' do
          expect(build(:container_repository, migration_state: 'pre_import_done')).to be_invalid
          expect(build(:container_repository, :pre_import_done)).to be_valid
        end
      end

      describe 'importing' do
        it 'validates expected attributes' do
          expect(build(:container_repository, migration_state: 'importing')).to be_invalid
          expect(build(:container_repository, :importing)).to be_valid
        end
      end

      describe 'import_skipped' do
        it 'validates expected attributes' do
          expect(build(:container_repository, migration_state: 'import_skipped')).to be_invalid
          expect(build(:container_repository, :import_skipped)).to be_valid
        end
      end

      describe 'import_aborted' do
        it 'validates expected attributes' do
          expect(build(:container_repository, migration_state: 'import_aborted')).to be_invalid
          expect(build(:container_repository, :import_aborted)).to be_valid
        end
      end
    end
  end

  context ':migration_state state_machine' do
    shared_examples 'no action when feature flag is disabled' do
      context 'feature flag disabled' do
        before do
          stub_feature_flags(container_registry_migration_phase2_enabled: false)
        end

        it { is_expected.to eq(false) }
      end
    end

    shared_examples 'transitioning to pre_importing' do
      before do
        repository.update_column(:migration_pre_import_done_at, Time.zone.now)
      end

      it_behaves_like 'no action when feature flag is disabled'

      context 'successful pre_import request' do
        it 'sets migration_pre_import_started_at and resets migration_pre_import_done_at' do
          expect(repository).to receive(:migration_pre_import).and_return(:ok)

          expect { subject }.to change { repository.reload.migration_pre_import_started_at }
            .and change { repository.migration_pre_import_done_at }.to(nil)

          expect(repository).to be_pre_importing
        end
      end

      context 'failed pre_import request' do
        it 'sets migration_pre_import_started_at and resets migration_pre_import_done_at' do
          expect(repository).to receive(:migration_pre_import).and_return(:error)

          expect { subject }.to change { repository.reload.migration_pre_import_started_at }
            .and change { repository.migration_aborted_at }
            .and change { repository.migration_pre_import_done_at }.to(nil)

          expect(repository.migration_aborted_in_state).to eq('pre_importing')
          expect(repository).to be_import_aborted
        end
      end

      context 'already imported' do
        it 'finishes the import' do
          expect(repository).to receive(:migration_pre_import).and_return(:already_imported)

          expect { subject }
            .to change { repository.reload.migration_state }.to('import_done')
            .and change { repository.reload.migration_skipped_reason }.to('native_import')
        end
      end

      context 'non-existing repository' do
        it 'finishes the import' do
          expect(repository).to receive(:migration_pre_import).and_return(:not_found)

          expect { subject }
            .to change { repository.reload.migration_state }.to('import_done')
            .and change { repository.migration_skipped_reason }.to('not_found')
            .and change { repository.migration_import_done_at }.from(nil)
        end
      end
    end

    shared_examples 'transitioning to importing' do
      before do
        repository.update_columns(migration_import_done_at: Time.zone.now)
      end

      context 'successful import request' do
        it 'sets migration_import_started_at and resets migration_import_done_at' do
          expect(repository).to receive(:migration_import).and_return(:ok)

          expect { subject }.to change { repository.reload.migration_import_started_at }
            .and change { repository.migration_import_done_at }.to(nil)

          expect(repository).to be_importing
        end
      end

      context 'failed import request' do
        it 'sets migration_import_started_at and resets migration_import_done_at' do
          expect(repository).to receive(:migration_import).and_return(:error)

          expect { subject }.to change { repository.reload.migration_import_started_at }
            .and change { repository.migration_aborted_at }

          expect(repository.migration_aborted_in_state).to eq('importing')
          expect(repository).to be_import_aborted
        end
      end

      context 'already imported' do
        it 'finishes the import' do
          expect(repository).to receive(:migration_import).and_return(:already_imported)

          expect { subject }
            .to change { repository.reload.migration_state }.to('import_done')
            .and change { repository.reload.migration_skipped_reason }.to('native_import')
        end
      end
    end

    shared_examples 'transitioning out of import_aborted' do
      it 'resets migration_aborted_at and migration_aborted_in_state' do
        expect { subject }.to change { repository.reload.migration_aborted_in_state }.to(nil)
          .and change { repository.migration_aborted_at }.to(nil)
      end
    end

    shared_examples 'transitioning from allowed states' do |allowed_states|
      described_class::MIGRATION_STATES.each do |state|
        result = allowed_states.include?(state)

        context "when transitioning from #{state}" do
          let(:repository) { create(:container_repository, state.to_sym) }

          it "returns #{result}" do
            expect(subject).to eq(result)
          end
        end
      end
    end

    shared_examples 'queueing the next import' do
      it 'starts the worker' do
        expect(::ContainerRegistry::Migration::EnqueuerWorker).to receive(:perform_async)

        subject
      end
    end

    describe '#start_pre_import' do
      let_it_be_with_reload(:repository) { create(:container_repository) }

      subject { repository.start_pre_import }

      before do |example|
        allow(repository).to receive(:migration_pre_import).and_return(:ok)
      end

      it_behaves_like 'transitioning from allowed states', %w[default pre_importing importing import_aborted]
      it_behaves_like 'transitioning to pre_importing'
    end

    describe '#retry_pre_import' do
      let_it_be_with_reload(:repository) { create(:container_repository, :import_aborted) }

      subject { repository.retry_pre_import }

      before do |example|
        allow(repository).to receive(:migration_pre_import).and_return(:ok)
      end

      it_behaves_like 'transitioning from allowed states', %w[pre_importing importing import_aborted]
      it_behaves_like 'transitioning to pre_importing'
      it_behaves_like 'transitioning out of import_aborted'
    end

    describe '#finish_pre_import' do
      let_it_be_with_reload(:repository) { create(:container_repository, :pre_importing) }

      subject { repository.finish_pre_import }

      it_behaves_like 'transitioning from allowed states', %w[pre_importing importing import_aborted]

      it 'sets migration_pre_import_done_at' do
        expect { subject }.to change { repository.reload.migration_pre_import_done_at }

        expect(repository).to be_pre_import_done
      end
    end

    describe '#start_import' do
      let_it_be_with_reload(:repository) { create(:container_repository, :pre_import_done) }

      subject { repository.start_import }

      before do |example|
        allow(repository).to receive(:migration_import).and_return(:ok)
      end

      it_behaves_like 'transitioning from allowed states', %w[pre_import_done pre_importing importing import_aborted]
      it_behaves_like 'transitioning to importing'
    end

    describe '#retry_import' do
      let_it_be_with_reload(:repository) { create(:container_repository, :import_aborted) }

      subject { repository.retry_import }

      before do |example|
        allow(repository).to receive(:migration_import).and_return(:ok)
      end

      it_behaves_like 'transitioning from allowed states', %w[pre_importing importing import_aborted]
      it_behaves_like 'transitioning to importing'
      it_behaves_like 'no action when feature flag is disabled'
    end

    describe '#finish_import' do
      let_it_be_with_reload(:repository) { create(:container_repository, :importing) }

      subject { repository.finish_import }

      it_behaves_like 'transitioning from allowed states', %w[default pre_importing importing import_aborted]
      it_behaves_like 'queueing the next import'

      it 'sets migration_import_done_at and queues the next import' do
        expect { subject }.to change { repository.reload.migration_import_done_at }

        expect(repository).to be_import_done
      end
    end

    describe '#already_migrated' do
      let_it_be_with_reload(:repository) { create(:container_repository) }

      subject { repository.already_migrated }

      it_behaves_like 'transitioning from allowed states', %w[default]

      it 'sets migration_import_done_at' do
        subject

        expect(repository).to be_import_done
      end
    end

    describe '#abort_import' do
      let_it_be_with_reload(:repository) { create(:container_repository, :importing) }

      subject { repository.abort_import }

      it_behaves_like 'transitioning from allowed states', ContainerRepository::ABORTABLE_MIGRATION_STATES
      it_behaves_like 'queueing the next import'

      it 'sets migration_aborted_at and migration_aborted_at, increments the retry count, and queues the next import' do
        expect { subject }.to change { repository.migration_aborted_at }
          .and change { repository.reload.migration_retries_count }.by(1)

        expect(repository.migration_aborted_in_state).to eq('importing')
        expect(repository).to be_import_aborted
      end

      context 'above the max retry limit' do
        before do
          stub_application_setting(container_registry_import_max_retries: 1)
        end

        it 'skips the migration' do
          expect { subject }.to change { repository.migration_skipped_at }

          expect(repository.reload).to be_import_skipped
          expect(repository.migration_skipped_reason).to eq('too_many_retries')
        end
      end
    end

    describe '#skip_import' do
      let_it_be_with_reload(:repository) { create(:container_repository) }

      subject { repository.skip_import(reason: :too_many_retries) }

      it_behaves_like 'transitioning from allowed states', ContainerRepository::SKIPPABLE_MIGRATION_STATES
      it_behaves_like 'queueing the next import'

      it 'sets migration_skipped_at and migration_skipped_reason' do
        expect { subject }.to change { repository.reload.migration_skipped_at }

        expect(repository.migration_skipped_reason).to eq('too_many_retries')
        expect(repository).to be_import_skipped
      end

      it 'raises and error if a reason is not given' do
        expect { repository.skip_import }.to raise_error(ArgumentError)
      end
    end

    describe '#finish_pre_import_and_start_import' do
      let_it_be_with_reload(:repository) { create(:container_repository, :pre_importing) }

      subject { repository.finish_pre_import_and_start_import }

      before do |example|
        allow(repository).to receive(:migration_import).and_return(:ok)
      end

      it_behaves_like 'transitioning from allowed states', %w[pre_importing importing import_aborted]
      it_behaves_like 'transitioning to importing'
    end
  end

  context 'when triggering registry API requests' do
    let(:repository_state) { nil }
    let(:repository) { create(:container_repository, repository_state) }

    shared_examples 'a state machine configured with use_transactions: false' do
      it 'executes the registry API request outside of a transaction', :delete do
        expect(repository).to receive(:save).and_call_original do
          expect(ApplicationRecord.connection.transaction_open?).to be true
        end

        expect(repository).to receive(:try_import) do
          expect(ApplicationRecord.connection.transaction_open?).to be false
        end

        subject
      end
    end

    context 'when responding to a start_pre_import event' do
      subject { repository.start_pre_import }

      it_behaves_like 'a state machine configured with use_transactions: false'
    end

    context 'when responding to a retry_pre_import event' do
      let(:repository_state) { :import_aborted }

      subject { repository.retry_pre_import }

      it_behaves_like 'a state machine configured with use_transactions: false'
    end

    context 'when responding to a start_import event' do
      let(:repository_state) { :pre_import_done }

      subject { repository.start_import }

      it_behaves_like 'a state machine configured with use_transactions: false'
    end

    context 'when responding to a retry_import event' do
      let(:repository_state) { :import_aborted }

      subject { repository.retry_import }

      it_behaves_like 'a state machine configured with use_transactions: false'
    end
  end

  describe '#retry_aborted_migration' do
    subject { repository.retry_aborted_migration }

    context 'when migration_state is not aborted' do
      it 'does nothing' do
        expect { subject }.not_to change { repository.reload.migration_state }

        expect(subject).to eq(nil)
      end
    end

    context 'when migration_state is aborted' do
      before do
        repository.abort_import

        allow(repository.gitlab_api_client)
            .to receive(:import_status).with(repository.path).and_return(status)
      end

      it_behaves_like 'reconciling migration_state' do
        context 'error response' do
          let(:status) { 'error' }

          context 'migration_pre_import_done_at is NULL' do
            it_behaves_like 'retrying the pre_import'
          end

          context 'migration_pre_import_done_at is not NULL' do
            before do
              repository.update_columns(
                migration_pre_import_started_at: 5.minutes.ago,
                migration_pre_import_done_at: Time.zone.now
              )
            end

            it_behaves_like 'retrying the import'
          end
        end
      end
    end
  end

  describe '#reconcile_import_status' do
    subject { repository.reconcile_import_status(status) }

    before do
      repository.abort_import
    end

    it_behaves_like 'reconciling migration_state'
  end

  describe '#tag' do
    it 'has a test tag' do
      expect(repository.tag('test')).not_to be_nil
    end
  end

  describe '#path' do
    context 'when project path does not contain uppercase letters' do
      it 'returns a full path to the repository' do
        expect(repository.path).to eq('group/test/my_image')
      end
    end

    context 'when path contains uppercase letters' do
      let(:project) { create(:project, :repository, path: 'MY_PROJECT', group: group) }

      it 'returns a full path without capital letters' do
        expect(repository.path).to eq('group/my_project/my_image')
      end
    end
  end

  describe '#manifest' do
    it 'returns non-empty manifest' do
      expect(repository.manifest).not_to be_nil
    end
  end

  describe '#valid?' do
    it 'is a valid repository' do
      expect(repository).to be_valid
    end
  end

  describe '#tags' do
    it 'returns non-empty tags list' do
      expect(repository.tags).not_to be_empty
    end
  end

  describe '#each_tags_page' do
    let(:page_size) { 100 }

    before do
      allow(repository).to receive(:migrated?).and_return(true)
    end

    shared_examples 'iterating through a page' do |expected_tags: true|
      it 'iterates through one page' do
        expect(repository.gitlab_api_client).to receive(:tags)
                                                  .with(repository.path, page_size: page_size, last: nil)
                                                  .and_return(client_response)
        expect { |b| repository.each_tags_page(page_size: page_size, &b) }
          .to yield_with_args(expected_tags ? expected_tags_from(client_response_tags) : [])
      end
    end

    context 'with an empty page' do
      let(:client_response) { { pagination: {}, response_body: [] } }

      it_behaves_like 'iterating through a page', expected_tags: false
    end

    context 'with one page' do
      let(:client_response) { { pagination: {}, response_body: client_response_tags } }
      let(:client_response_tags) do
        [
          {
            'name' => '0.1.0',
            'created_at' => '2022-06-07T12:10:12.412+00:00'
          },
          {
            'name' => 'latest',
            'created_at' => '2022-06-07T12:11:13.633+00:00'
          }
        ]
      end

      context 'with a nil created_at' do
        let(:client_response_tags) { ['name' => '0.1.0', 'created_at' => nil] }

        it_behaves_like 'iterating through a page'
      end

      context 'with an invalid created_at' do
        let(:client_response_tags) { ['name' => '0.1.0', 'created_at' => 'not_a_timestamp'] }

        it_behaves_like 'iterating through a page'
      end
    end

    context 'with two pages' do
      let(:client_response1) { { pagination: { next: { uri: URI('http://localhost/next?last=latest') } }, response_body: client_response_tags1 } }
      let(:client_response_tags1) do
        [
          {
            'name' => '0.1.0',
            'created_at' => '2022-06-07T12:10:12.412+00:00'
          },
          {
            'name' => 'latest',
            'created_at' => '2022-06-07T12:11:13.633+00:00'
          }
        ]
      end

      let(:client_response2) { { pagination: {}, response_body: client_response_tags2 } }
      let(:client_response_tags2) do
        [
          {
            'name' => '1.2.3',
            'created_at' => '2022-06-10T12:10:15.412+00:00'
          },
          {
            'name' => '2.3.4',
            'created_at' => '2022-06-11T12:11:17.633+00:00'
          }
        ]
      end

      it 'iterates through two pages' do
        expect(repository.gitlab_api_client).to receive(:tags)
                                                  .with(repository.path, page_size: page_size, last: nil)
                                                  .and_return(client_response1)
        expect(repository.gitlab_api_client).to receive(:tags)
                                                  .with(repository.path, page_size: page_size, last: 'latest')
                                                  .and_return(client_response2)
        expect { |b| repository.each_tags_page(page_size: page_size, &b) }
          .to yield_successive_args(expected_tags_from(client_response_tags1), expected_tags_from(client_response_tags2))
      end
    end

    context 'when max pages is reached' do
      before do
        stub_const('ContainerRepository::MAX_TAGS_PAGES', 0)
      end

      it 'raises an error' do
        expect { repository.each_tags_page(page_size: page_size) {} }
          .to raise_error(StandardError, 'too many pages requested')
      end
    end

    context 'without a block set' do
      it 'raises an Argument error' do
        expect { repository.each_tags_page(page_size: page_size) }.to raise_error(ArgumentError, 'block not given')
      end
    end

    context 'without a page size set' do
      let(:client_response) { { pagination: {}, response_body: [] } }

      it 'uses a default size' do
        expect(repository.gitlab_api_client).to receive(:tags)
                                                  .with(repository.path, page_size: 100, last: nil)
                                                  .and_return(client_response)
        expect { |b| repository.each_tags_page(&b) }.to yield_with_args([])
      end
    end

    context 'with an empty client response' do
      let(:client_response) { {} }

      it 'breaks the loop' do
        expect(repository.gitlab_api_client).to receive(:tags)
                                                  .with(repository.path, page_size: page_size, last: nil)
                                                  .and_return(client_response)
        expect { |b| repository.each_tags_page(page_size: page_size, &b) }.not_to yield_control
      end
    end

    context 'with a nil page' do
      let(:client_response) { { pagination: {}, response_body: nil } }

      it_behaves_like 'iterating through a page', expected_tags: false
    end

    context 'calling on a non migrated repository' do
      before do
        allow(repository).to receive(:migrated?).and_return(false)
      end

      it 'raises an Argument error' do
        expect { repository.each_tags_page }.to raise_error(ArgumentError, 'not a migrated repository')
      end
    end

    def expected_tags_from(client_tags)
      client_tags.map do |tag|
        created_at =
          begin
            DateTime.iso8601(tag['created_at'])
          rescue ArgumentError
            nil
          end
        an_object_having_attributes(name: tag['name'], created_at: created_at)
      end
    end
  end

  describe '#tags_count' do
    it 'returns the count of tags' do
      expect(repository.tags_count).to eq(1)
    end
  end

  describe '#has_tags?' do
    it 'has tags' do
      expect(repository).to have_tags
    end
  end

  describe '#delete_tags!' do
    let(:repository) do
      create(
        :container_repository,
        name: 'my_image',
        tags: { latest: '123', rc1: '234' },
        project: project
      )
    end

    context 'when action succeeds' do
      it 'returns status that indicates success' do
        expect(repository.client)
          .to receive(:delete_repository_tag_by_digest)
          .twice
          .and_return(true)

        expect(repository.delete_tags!).to be_truthy
      end
    end

    context 'when action fails' do
      it 'returns status that indicates failure' do
        expect(repository.client)
          .to receive(:delete_repository_tag_by_digest)
          .twice
          .and_return(false)

        expect(repository.delete_tags!).to be_falsey
      end
    end
  end

  describe '#delete_tag_by_name' do
    let(:repository) do
      create(
        :container_repository,
        name: 'my_image',
        tags: { latest: '123', rc1: '234' },
        project: project
      )
    end

    context 'when action succeeds' do
      it 'returns status that indicates success' do
        expect(repository.client)
          .to receive(:delete_repository_tag_by_name)
          .with(repository.path, "latest")
          .and_return(true)

        expect(repository.delete_tag_by_name('latest')).to be_truthy
      end
    end

    context 'when action fails' do
      it 'returns status that indicates failure' do
        expect(repository.client)
          .to receive(:delete_repository_tag_by_name)
          .with(repository.path, "latest")
          .and_return(false)

        expect(repository.delete_tag_by_name('latest')).to be_falsey
      end
    end
  end

  describe '#location' do
    context 'when registry is running on a custom port' do
      before do
        stub_container_registry_config(
          enabled: true,
          api_url: 'http://registry.gitlab:5000',
          host_port: 'registry.gitlab:5000'
        )
      end

      it 'returns a full location of the repository' do
        expect(repository.location)
          .to eq 'registry.gitlab:5000/group/test/my_image'
      end
    end
  end

  describe '#root_repository?' do
    context 'when repository is a root repository' do
      let(:repository) { create(:container_repository, :root) }

      it 'returns true' do
        expect(repository).to be_root_repository
      end
    end

    context 'when repository is not a root repository' do
      it 'returns false' do
        expect(repository).not_to be_root_repository
      end
    end
  end

  describe '#start_expiration_policy!' do
    subject { repository.start_expiration_policy! }

    before do
      repository.update_column(:last_cleanup_deleted_tags_count, 10)
    end

    it 'sets the expiration policy started at to now' do
      freeze_time do
        expect { subject }
          .to change { repository.expiration_policy_started_at }.from(nil).to(Time.zone.now)
          .and change { repository.expiration_policy_cleanup_status }.from('cleanup_unscheduled').to('cleanup_ongoing')
          .and change { repository.last_cleanup_deleted_tags_count }.from(10).to(nil)
      end
    end
  end

  describe '#size' do
    let(:on_com) { true }
    let(:created_at) { described_class::MIGRATION_PHASE_1_STARTED_AT + 3.months }

    subject { repository.size }

    before do
      allow(::Gitlab).to receive(:com?).and_return(on_com)
      allow(repository).to receive(:created_at).and_return(created_at)
    end

    context 'supports gitlab api on .com with a recent repository' do
      before do
        expect(repository.gitlab_api_client).to receive(:supports_gitlab_api?).and_return(true)
        expect(repository.gitlab_api_client).to receive(:repository_details).with(repository.path, sizing: :self).and_return(response)
      end

      context 'with a size_bytes field' do
        let(:response) { { 'size_bytes' => 12345 } }

        it { is_expected.to eq(12345) }
      end

      context 'without a size_bytes field' do
        let(:response) { { 'foo' => 'bar' } }

        it { is_expected.to eq(nil) }
      end
    end

    context 'does not support gitlab api' do
      before do
        expect(repository.gitlab_api_client).to receive(:supports_gitlab_api?).and_return(false)
        expect(repository.gitlab_api_client).not_to receive(:repository_details)
      end

      it { is_expected.to eq(nil) }
    end

    context 'not on .com' do
      let(:on_com) { false }

      it { is_expected.to eq(nil) }
    end

    context 'supports gitlab api on .com with an old repository' do
      let(:on_com) { true }
      let(:created_at) { described_class::MIGRATION_PHASE_1_STARTED_AT - 3.months }

      before do
        allow(repository.gitlab_api_client).to receive(:supports_gitlab_api?).and_return(true)
        allow(repository.gitlab_api_client).to receive(:repository_details).with(repository.path, sizing: :self).and_return(response)
        expect(repository).to receive(:migration_state).and_return(migration_state)
      end

      context 'with migration_state import_done' do
        let(:response) { { 'size_bytes' => 12345 } }
        let(:migration_state) { 'import_done' }

        it { is_expected.to eq(12345) }
      end

      context 'with migration_state not import_done' do
        let(:response) { { 'size_bytes' => 12345 } }
        let(:migration_state) { 'default' }

        it { is_expected.to eq(nil) }
      end
    end
  end

  describe '#set_delete_ongoing_status', :freeze_time do
    let_it_be(:repository) { create(:container_repository) }

    subject { repository.set_delete_ongoing_status }

    it 'updates deletion status attributes' do
      expect { subject }.to change(repository, :status).from(nil).to('delete_ongoing')
                              .and change(repository, :delete_started_at).from(nil).to(Time.zone.now)
                              .and change(repository, :status_updated_at).from(nil).to(Time.zone.now)
    end
  end

  describe '#set_delete_scheduled_status', :freeze_time do
    let_it_be(:repository) { create(:container_repository, :status_delete_ongoing, delete_started_at: 3.minutes.ago) }

    subject { repository.set_delete_scheduled_status }

    it 'updates delete attributes' do
      expect { subject }.to change(repository, :status).from('delete_ongoing').to('delete_scheduled')
                              .and change(repository, :delete_started_at).to(nil)
                              .and change(repository, :status_updated_at).to(Time.zone.now)
    end
  end

  describe '#status_updated_at', :freeze_time do
    let_it_be_with_reload(:repository) { create(:container_repository) }

    %i[delete_scheduled delete_ongoing delete_failed].each do |status|
      context "when status is updated to #{status}" do
        it 'updates status_changed_at' do
          expect { repository.update!(status: status) }.to change(repository, :status_updated_at).from(nil).to(Time.zone.now)
        end
      end
    end

    context 'when status is not changed' do
      it 'does not update status_changed_at' do
        repository.name = 'different-image'

        expect { repository.save! }.not_to change(repository, :status_updated_at)
      end
    end
  end

  context 'registry migration' do
    before do
      allow(repository.gitlab_api_client).to receive(:supports_gitlab_api?).and_return(true)
    end

    shared_examples 'gitlab migration client request' do |step|
      let(:client_response) { :foobar }

      it 'returns the same response as the client' do
        expect(repository.gitlab_api_client)
          .to receive(step).with(repository.path).and_return(client_response)
        expect(subject).to eq(client_response)
      end

      context 'when the gitlab_api feature is not supported' do
        before do
          allow(repository.gitlab_api_client).to receive(:supports_gitlab_api?).and_return(false)
        end

        it 'returns :error' do
          expect(repository.gitlab_api_client).not_to receive(step)

          expect(subject).to eq(:error)
        end
      end
    end

    shared_examples 'handling the migration step' do |step|
      it_behaves_like 'gitlab migration client request', step

      context 'too many imports' do
        it 'raises an error when it receives too_many_imports as a response' do
          expect(repository.gitlab_api_client)
            .to receive(step).with(repository.path).and_return(:too_many_imports)
          expect { subject }.to raise_error(described_class::TooManyImportsError)
        end
      end
    end

    describe '#migration_pre_import' do
      subject { repository.migration_pre_import }

      it_behaves_like 'handling the migration step', :pre_import_repository
    end

    describe '#migration_import' do
      subject { repository.migration_import }

      it_behaves_like 'handling the migration step', :import_repository
    end

    describe '#migration_cancel' do
      subject { repository.migration_cancel }

      it_behaves_like 'gitlab migration client request', :cancel_repository_import
    end

    describe '#force_migration_cancel' do
      subject { repository.force_migration_cancel }

      shared_examples 'returning the same response as the client' do
        it 'returns the same response' do
          expect(repository.gitlab_api_client)
            .to receive(:cancel_repository_import).with(repository.path, force: true).and_return(client_response)

          expect(subject).to eq(client_response)
        end
      end

      context 'successful cancellation' do
        let(:client_response) { { status: :ok } }

        it_behaves_like 'returning the same response as the client'

        it 'skips the migration' do
          expect(repository.gitlab_api_client)
            .to receive(:cancel_repository_import).with(repository.path, force: true).and_return(client_response)

          expect { subject }.to change { repository.reload.migration_state }.to('import_skipped')
            .and change { repository.migration_skipped_reason }.to('migration_forced_canceled')
            .and change { repository.migration_skipped_at }
        end
      end

      context 'failed cancellation' do
        let(:client_response) { { status: :error } }

        it_behaves_like 'returning the same response as the client'

        it 'does not skip the migration' do
          expect(repository.gitlab_api_client)
            .to receive(:cancel_repository_import).with(repository.path, force: true).and_return(client_response)

          expect { subject }.to not_change { repository.reload.migration_state }
            .and not_change { repository.migration_skipped_reason }
            .and not_change { repository.migration_skipped_at }
        end
      end

      context 'when the gitlab_api feature is not supported' do
        before do
          allow(repository.gitlab_api_client).to receive(:supports_gitlab_api?).and_return(false)
        end

        it 'returns :error' do
          expect(repository.gitlab_api_client).not_to receive(:cancel_repository_import)

          expect(subject).to eq(:error)
        end
      end
    end
  end

  describe '.build_from_path' do
    let(:registry_path) do
      ContainerRegistry::Path.new(project.full_path + '/some/image')
    end

    let(:repository) do
      described_class.build_from_path(registry_path)
    end

    it 'fabricates repository assigned to a correct project' do
      expect(repository.project).to eq project
    end

    it 'fabricates repository with a correct name' do
      expect(repository.name).to eq 'some/image'
    end

    it 'is not persisted' do
      expect(repository).not_to be_persisted
    end
  end

  describe '.find_or_create_from_path' do
    let(:repository) do
      described_class.find_or_create_from_path(ContainerRegistry::Path.new(path))
    end

    let(:repository_path) { ContainerRegistry::Path.new(path) }

    context 'when received multi-level repository path' do
      let(:path) { project.full_path + '/some/image' }

      it 'fabricates repository assigned to a correct project' do
        expect(repository.project).to eq project
      end

      it 'fabricates repository with a correct name' do
        expect(repository.name).to eq 'some/image'
      end
    end

    context 'when path is too long' do
      let(:path) do
        project.full_path + '/a/b/c/d/e/f/g/h/i/j/k/l/n/o/p/s/t/u/x/y/z'
      end

      it 'does not create repository and raises error' do
        expect { repository }.to raise_error(
          ContainerRegistry::Path::InvalidRegistryPathError)
      end
    end

    context 'when received multi-level repository with nested groups' do
      let(:group) { create(:group, :nested, name: 'nested') }
      let(:path) { project.full_path + '/some/image' }

      it 'fabricates repository assigned to a correct project' do
        expect(repository.project).to eq project
      end

      it 'fabricates repository with a correct name' do
        expect(repository.name).to eq 'some/image'
      end

      it 'has path including a nested group' do
        expect(repository.path).to include 'nested/test/some/image'
      end
    end

    context 'when received root repository path' do
      let(:path) { project.full_path }

      it 'fabricates repository assigned to a correct project' do
        expect(repository.project).to eq project
      end

      it 'fabricates repository with an empty name' do
        expect(repository.name).to be_empty
      end
    end

    context 'when repository already exists' do
      let(:path) { project.full_path + '/some/image' }

      it 'returns the existing repository' do
        container_repository = create(:container_repository, project: project, name: 'some/image')

        expect(repository.id).to eq(container_repository.id)
      end
    end

    context 'when many of the same repository are created at the same time' do
      let(:path) { ContainerRegistry::Path.new(project.full_path + '/some/image') }

      it 'does not throw validation errors and only creates one repository' do
        expect { repository_creation_race(path) }.to change { described_class.count }.by(1)
      end

      it 'retrieves a persisted repository for all concurrent calls' do
        repositories = repository_creation_race(path).map(&:value)

        expect(repositories).to all(be_persisted)
      end
    end

    def repository_creation_race(path)
      # create a race condition - structure from https://blog.arkency.com/2015/09/testing-race-conditions/
      wait_for_it = true

      threads = Array.new(10) do |i|
        Thread.new do
          true while wait_for_it

          described_class.find_or_create_from_path(path)
        end
      end
      wait_for_it = false
      threads.each(&:join)
    end
  end

  describe '.find_by_path' do
    let_it_be(:container_repository) { create(:container_repository) }
    let_it_be(:repository_path) { container_repository.project.full_path }

    let(:path) { ContainerRegistry::Path.new(repository_path + '/' + container_repository.name) }

    subject { described_class.find_by_path(path) }

    context 'when repository exists' do
      it 'finds the repository' do
        expect(subject).to eq(container_repository)
      end
    end

    context 'when repository does not exist' do
      let(:path) { ContainerRegistry::Path.new(repository_path + '/some/image') }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe '.find_by_path!' do
    let_it_be(:container_repository) { create(:container_repository) }
    let_it_be(:repository_path) { container_repository.project.full_path }

    let(:path) { ContainerRegistry::Path.new(repository_path + '/' + container_repository.name) }

    subject { described_class.find_by_path!(path) }

    context 'when repository exists' do
      it 'finds the repository' do
        expect(subject).to eq(container_repository)
      end
    end

    context 'when repository does not exist' do
      let(:path) { ContainerRegistry::Path.new(repository_path + '/some/image') }

      it 'raises an exception' do
        expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '.build_root_repository' do
    let(:repository) do
      described_class.build_root_repository(project)
    end

    it 'fabricates a root repository object' do
      expect(repository).to be_root_repository
    end

    it 'assignes it to the correct project' do
      expect(repository.project).to eq project
    end

    it 'does not persist it' do
      expect(repository).not_to be_persisted
    end
  end

  describe '.for_group_and_its_subgroups' do
    subject { described_class.for_group_and_its_subgroups(test_group) }

    context 'in a group' do
      let(:test_group) { group }

      it { is_expected.to contain_exactly(repository) }
    end

    context 'with a subgroup' do
      let_it_be(:test_group) { create(:group) }
      let_it_be(:another_project) { create(:project, path: 'test', group: test_group) }
      let_it_be(:project3) { create(:project, :container_registry_disabled, path: 'test3', group: test_group) }

      let_it_be(:another_repository) do
        create(:container_repository, name: 'my_image', project: another_project)
      end

      let_it_be(:repository3) do
        create(:container_repository, name: 'my_image3', project: project3)
      end

      before do
        allow(group).to receive(:first_project_with_container_registry_tags).and_return(nil)

        group.parent = test_group
        group.save!
      end

      it { is_expected.to contain_exactly(repository, another_repository) }
    end

    context 'group without container_repositories' do
      let(:test_group) { create(:group) }

      it { is_expected.to eq([]) }
    end
  end

  describe '.search_by_name' do
    let!(:another_repository) do
      create(:container_repository, name: 'my_foo_bar', project: project)
    end

    subject { described_class.search_by_name('my_image') }

    it { is_expected.to contain_exactly(repository) }
  end

  describe '.for_project_id' do
    subject { described_class.for_project_id(project.id) }

    it { is_expected.to contain_exactly(repository) }
  end

  describe '.expiration_policy_started_at_nil_or_before' do
    let_it_be(:repository1) { create(:container_repository, expiration_policy_started_at: nil) }
    let_it_be(:repository2) { create(:container_repository, expiration_policy_started_at: 1.day.ago) }
    let_it_be(:repository3) { create(:container_repository, expiration_policy_started_at: 2.hours.ago) }
    let_it_be(:repository4) { create(:container_repository, expiration_policy_started_at: 1.week.ago) }

    subject { described_class.expiration_policy_started_at_nil_or_before(3.hours.ago) }

    it { is_expected.to contain_exactly(repository1, repository2, repository4) }
  end

  describe '.with_migration_import_started_at_nil_or_before' do
    let_it_be(:repository1) { create(:container_repository, migration_import_started_at: 5.minutes.ago) }
    let_it_be(:repository2) { create(:container_repository, migration_import_started_at: nil) }
    let_it_be(:repository3) { create(:container_repository, migration_import_started_at: 10.minutes.ago) }

    subject { described_class.with_migration_import_started_at_nil_or_before(7.minutes.ago) }

    it { is_expected.to contain_exactly(repository2, repository3) }
  end

  describe '.with_migration_pre_import_started_at_nil_or_before' do
    let_it_be(:repository1) { create(:container_repository, migration_pre_import_started_at: 5.minutes.ago) }
    let_it_be(:repository2) { create(:container_repository, migration_pre_import_started_at: nil) }
    let_it_be(:repository3) { create(:container_repository, migration_pre_import_started_at: 10.minutes.ago) }

    subject { described_class.with_migration_pre_import_started_at_nil_or_before(7.minutes.ago) }

    it { is_expected.to contain_exactly(repository2, repository3) }
  end

  describe '.with_migration_pre_import_done_at_nil_or_before' do
    let_it_be(:repository1) { create(:container_repository, migration_pre_import_done_at: 5.minutes.ago) }
    let_it_be(:repository2) { create(:container_repository, migration_pre_import_done_at: nil) }
    let_it_be(:repository3) { create(:container_repository, migration_pre_import_done_at: 10.minutes.ago) }

    subject { described_class.with_migration_pre_import_done_at_nil_or_before(7.minutes.ago) }

    it { is_expected.to contain_exactly(repository2, repository3) }
  end

  describe '.with_stale_ongoing_cleanup' do
    let_it_be(:repository1) { create(:container_repository, :cleanup_ongoing, expiration_policy_started_at: 1.day.ago) }
    let_it_be(:repository2) { create(:container_repository, :cleanup_ongoing, expiration_policy_started_at: 25.minutes.ago) }
    let_it_be(:repository3) { create(:container_repository, :cleanup_ongoing, expiration_policy_started_at: 1.week.ago) }
    let_it_be(:repository4) { create(:container_repository, :cleanup_unscheduled, expiration_policy_started_at: 25.minutes.ago) }

    subject { described_class.with_stale_ongoing_cleanup(27.minutes.ago) }

    it { is_expected.to contain_exactly(repository1, repository3) }
  end

  describe '.with_stale_delete_at' do
    let_it_be(:repository1) { create(:container_repository, delete_started_at: 1.day.ago) }
    let_it_be(:repository2) { create(:container_repository, delete_started_at: 25.minutes.ago) }
    let_it_be(:repository3) { create(:container_repository, delete_started_at: 1.week.ago) }

    subject { described_class.with_stale_delete_at(27.minutes.ago) }

    it { is_expected.to contain_exactly(repository1, repository3) }
  end

  describe '.waiting_for_cleanup' do
    let_it_be(:repository_cleanup_scheduled) { create(:container_repository, :cleanup_scheduled) }
    let_it_be(:repository_cleanup_unfinished) { create(:container_repository, :cleanup_unfinished) }
    let_it_be(:repository_cleanup_ongoing) { create(:container_repository, :cleanup_ongoing) }

    subject { described_class.waiting_for_cleanup }

    it { is_expected.to contain_exactly(repository_cleanup_scheduled, repository_cleanup_unfinished) }
  end

  describe '.exists_by_path?' do
    it 'returns true for known container repository paths' do
      path = ContainerRegistry::Path.new("#{project.full_path}/#{repository.name}")
      expect(described_class.exists_by_path?(path)).to be_truthy
    end

    it 'returns false for unknown container repository paths' do
      path = ContainerRegistry::Path.new('you/dont/know/me')
      expect(described_class.exists_by_path?(path)).to be_falsey
    end
  end

  describe '.all_migrated?' do
    let_it_be(:project) { create(:project) }

    subject { project.container_repositories.all_migrated? }

    context 'with no repositories' do
      it { is_expected.to be_truthy }
    end

    context 'with only recent repositories' do
      let_it_be(:container_repository1) { create(:container_repository, project: project) }
      let_it_be_with_reload(:container_repository2) { create(:container_repository, project: project) }

      it { is_expected.to be_truthy }

      context 'with one old non migrated repository' do
        before do
          container_repository2.update!(created_at: described_class::MIGRATION_PHASE_1_ENDED_AT - 3.months)
        end

        it { is_expected.to be_falsey }
      end

      context 'with one old migrated repository' do
        before do
          container_repository2.update!(
            created_at: described_class::MIGRATION_PHASE_1_ENDED_AT - 3.months,
            migration_state: 'import_done',
            migration_import_done_at: Time.zone.now
          )
        end

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '.with_enabled_policy' do
    let_it_be(:repository) { create(:container_repository) }
    let_it_be(:repository2) { create(:container_repository) }

    subject { described_class.with_enabled_policy }

    before do
      repository.project.container_expiration_policy.update!(enabled: true)
    end

    it { is_expected.to eq([repository]) }
  end

  describe '#migration_in_active_state?' do
    subject { container_repository.migration_in_active_state? }

    described_class::MIGRATION_STATES.each do |state|
      context "when in #{state} migration_state" do
        let(:container_repository) { create(:container_repository, state.to_sym) }

        it { is_expected.to eq(state == 'importing' || state == 'pre_importing') }
      end
    end
  end

  describe '#migration_importing?' do
    subject { container_repository.migration_importing? }

    described_class::MIGRATION_STATES.each do |state|
      context "when in #{state} migration_state" do
        let(:container_repository) { create(:container_repository, state.to_sym) }

        it { is_expected.to eq(state == 'importing') }
      end
    end
  end

  describe '#migration_pre_importing?' do
    subject { container_repository.migration_pre_importing? }

    described_class::MIGRATION_STATES.each do |state|
      context "when in #{state} migration_state" do
        let(:container_repository) { create(:container_repository, state.to_sym) }

        it { is_expected.to eq(state == 'pre_importing') }
      end
    end
  end

  describe '#try_import' do
    let_it_be_with_reload(:container_repository) { create(:container_repository) }

    let(:response) { nil }

    subject do
      container_repository.try_import do
        container_repository.foo
      end
    end

    before do
      allow(container_repository).to receive(:foo).and_return(response)
    end

    context 'successful request' do
      let(:response) { :ok }

      it { is_expected.to eq(true) }
    end

    context 'TooManyImportsError' do
      before do
        stub_application_setting(container_registry_import_start_max_retries: 3)
        allow(container_repository).to receive(:foo).and_raise(described_class::TooManyImportsError)
      end

      it 'tries again exponentially and aborts the migration' do
        expect(container_repository).to receive(:sleep).with(a_value_within(0.01).of(0.1))
        expect(container_repository).to receive(:sleep).with(a_value_within(0.01).of(0.2))
        expect(container_repository).to receive(:sleep).with(a_value_within(0.01).of(0.3))

        expect(subject).to eq(false)

        expect(container_repository).to be_import_aborted
      end
    end

    context 'not found response' do
      let(:response) { :not_found }

      it 'completes the migration' do
        expect(subject).to eq(false)

        expect(container_repository).to be_import_done
        expect(container_repository.reload.migration_skipped_reason).to eq('not_found')
      end
    end

    context 'other response' do
      let(:response) { :error }

      it 'aborts the migration' do
        expect(subject).to eq(false)

        expect(container_repository).to be_import_aborted
      end
    end

    context 'with no block given' do
      it 'raises an error' do
        expect { container_repository.try_import }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#retried_too_many_times?' do
    subject { repository.retried_too_many_times? }

    before do
      stub_application_setting(container_registry_import_max_retries: 3)
    end

    context 'migration_retries_count is equal or greater than max_retries' do
      before do
        repository.update_column(:migration_retries_count, 3)
      end

      it { is_expected.to eq(true) }
    end

    context 'migration_retries_count is lower than max_retries' do
      before do
        repository.update_column(:migration_retries_count, 2)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '#nearing_or_exceeded_retry_limit?' do
    subject { repository.nearing_or_exceeded_retry_limit? }

    before do
      stub_application_setting(container_registry_import_max_retries: 3)
    end

    context 'migration_retries_count is 1 less than max_retries' do
      before do
        repository.update_column(:migration_retries_count, 2)
      end

      it { is_expected.to eq(true) }
    end

    context 'migration_retries_count is lower than max_retries' do
      before do
        repository.update_column(:migration_retries_count, 1)
      end

      it { is_expected.to eq(false) }
    end

    context 'migration_retries_count equal to or higher than max_retries' do
      before do
        repository.update_column(:migration_retries_count, 3)
      end

      it { is_expected.to eq(true) }
    end
  end

  describe '#migrated?' do
    subject { repository.migrated? }

    context 'on gitlab.com' do
      before do
        allow(::Gitlab).to receive(:com?).and_return(true)
      end

      it { is_expected.to eq(true) }
    end

    context 'not on gitlab.com' do
      before do
        allow(::Gitlab).to receive(:com?).and_return(false)
      end

      it { is_expected.to eq(false) }
    end
  end

  context 'with repositories' do
    let_it_be_with_reload(:repository) { create(:container_repository, :cleanup_unscheduled) }
    let_it_be(:other_repository) { create(:container_repository, :cleanup_unscheduled) }

    let(:policy) { repository.project.container_expiration_policy }

    before do
      ContainerExpirationPolicy.update_all(enabled: true)
    end

    describe '.requiring_cleanup' do
      subject { described_class.requiring_cleanup }

      context 'with next_run_at in the future' do
        before do
          policy.update_column(:next_run_at, 10.minutes.from_now)
        end

        it { is_expected.to eq([]) }
      end

      context 'with next_run_at in the past' do
        before do
          policy.update_column(:next_run_at, 10.minutes.ago)
        end

        it { is_expected.to eq([repository]) }
      end

      context 'with repository cleanup started at after policy next run at' do
        before do
          repository.update!(expiration_policy_started_at: policy.next_run_at + 5.minutes)
        end

        it { is_expected.to eq([]) }
      end
    end

    describe '.with_unfinished_cleanup' do
      subject { described_class.with_unfinished_cleanup }

      it { is_expected.to eq([]) }

      context 'with an unfinished repository' do
        before do
          repository.cleanup_unfinished!
        end

        it { is_expected.to eq([repository]) }
      end
    end

    describe '.recently_done_migration_step' do
      let_it_be(:import_done_repository) { create(:container_repository, :import_done, migration_pre_import_done_at: 3.days.ago, migration_import_done_at: 2.days.ago) }
      let_it_be(:import_aborted_repository) { create(:container_repository, :import_aborted, migration_pre_import_done_at: 5.days.ago, migration_aborted_at: 1.day.ago) }
      let_it_be(:pre_import_done_repository) { create(:container_repository, :pre_import_done, migration_pre_import_done_at: 1.hour.ago) }
      let_it_be(:import_skipped_repository) { create(:container_repository, :import_skipped, migration_skipped_at: 90.minutes.ago) }

      subject { described_class.recently_done_migration_step }

      it 'returns completed imports by done_at date' do
        expect(subject.to_a).to eq([pre_import_done_repository, import_skipped_repository, import_aborted_repository, import_done_repository])
      end
    end

    describe '.ready_for_import' do
      include_context 'importable repositories'

      subject { described_class.ready_for_import }

      before do
        stub_application_setting(container_registry_import_target_plan: valid_container_repository.migration_plan)
      end

      it 'returns valid container repositories' do
        expect(subject).to contain_exactly(valid_container_repository, valid_container_repository2)
      end
    end

    describe '#last_import_step_done_at' do
      let_it_be(:aborted_at) { Time.zone.now - 1.hour }
      let_it_be(:pre_import_done_at) { Time.zone.now - 2.hours }
      let_it_be(:skipped_at) { Time.zone.now - 3.hours }

      subject { repository.last_import_step_done_at }

      before do
        repository.update_columns(
          migration_pre_import_done_at: pre_import_done_at,
          migration_aborted_at: aborted_at,
          migration_skipped_at: skipped_at
        )
      end

      it { is_expected.to eq(aborted_at) }
    end
  end

  describe '#external_import_status' do
    subject { repository.external_import_status }

    it 'returns the response from the client' do
      expect(repository.gitlab_api_client).to receive(:import_status).with(repository.path).and_return('test')

      expect(subject).to eq('test')
    end
  end

  describe '.with_stale_migration' do
    let_it_be(:repository) { create(:container_repository) }
    let_it_be(:stale_pre_importing_old_timestamp) { create(:container_repository, :pre_importing, migration_pre_import_started_at: 10.minutes.ago) }
    let_it_be(:stale_pre_importing_nil_timestamp) { create(:container_repository, :pre_importing).tap { |r| r.update_column(:migration_pre_import_started_at, nil) } }
    let_it_be(:stale_pre_importing_recent_timestamp) { create(:container_repository, :pre_importing, migration_pre_import_started_at: 2.minutes.ago) }

    let_it_be(:stale_pre_import_done_old_timestamp) { create(:container_repository, :pre_import_done, migration_pre_import_done_at: 10.minutes.ago) }
    let_it_be(:stale_pre_import_done_nil_timestamp) { create(:container_repository, :pre_import_done).tap { |r| r.update_column(:migration_pre_import_done_at, nil) } }
    let_it_be(:stale_pre_import_done_recent_timestamp) { create(:container_repository, :pre_import_done, migration_pre_import_done_at: 2.minutes.ago) }

    let_it_be(:stale_importing_old_timestamp) { create(:container_repository, :importing, migration_import_started_at: 10.minutes.ago) }
    let_it_be(:stale_importing_nil_timestamp) { create(:container_repository, :importing).tap { |r| r.update_column(:migration_import_started_at, nil) } }
    let_it_be(:stale_importing_recent_timestamp) { create(:container_repository, :importing, migration_import_started_at: 2.minutes.ago) }

    let(:stale_migrations) do
      [
        stale_pre_importing_old_timestamp,
        stale_pre_importing_nil_timestamp,
        stale_pre_import_done_old_timestamp,
        stale_pre_import_done_nil_timestamp,
        stale_importing_old_timestamp,
        stale_importing_nil_timestamp
      ]
    end

    subject { described_class.with_stale_migration(5.minutes.ago) }

    it { is_expected.to contain_exactly(*stale_migrations) }
  end

  describe '#registry' do
    it 'caches the client' do
      registry = repository.registry
      registry1 = repository.registry
      registry2 = nil

      travel_to(Time.current + Gitlab::CurrentSettings.container_registry_token_expire_delay.minutes) do
        registry2 = repository.registry
      end

      expect(registry1.object_id).to be(registry.object_id)
      expect(registry2.object_id).not_to be(registry.object_id)
    end
  end
end
