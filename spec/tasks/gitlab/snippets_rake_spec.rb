# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:snippets namespace rake task', :silence_stdout do
  let!(:user) { create(:user) }
  let!(:migrated) { create(:personal_snippet, :repository, author: user) }

  let(:non_migrated) { create_list(:personal_snippet, 3, author: user) }
  let(:non_migrated_ids) { non_migrated.pluck(:id) }

  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/snippets'
  end

  describe 'migrate' do
    subject { run_rake_task('gitlab:snippets:migrate') }

    before do
      stub_env('SNIPPET_IDS' => non_migrated_ids.join(','))
    end

    it 'looks up the appropriate shard' do
      # the default config/gitlab.yml gives nil for all workers
      expect(Gitlab::SidekiqSharding::Router).to receive(:get_shard_instance).with(nil).and_call_original

      subject
    end

    it 'can migrate specific snippets passing ids' do
      expect_next_instance_of(Gitlab::BackgroundMigration::BackfillSnippetRepositories) do |instance|
        expect(instance).to receive(:perform_by_ids).with(non_migrated_ids).and_call_original
      end

      expect { subject }.to output(/All snippets were migrated successfully/).to_stdout
    end

    it 'returns the ids of those snippet that failed the migration' do
      expect_next_instance_of(Gitlab::BackgroundMigration::BackfillSnippetRepositories) do |instance|
        expect(instance).to receive(:perform_by_ids).with(non_migrated_ids)
      end

      expect { subject }.to output(/The following snippets couldn't be migrated:\n#{non_migrated_ids.join(',')}/).to_stdout
    end

    it 'fails if the SNIPPET_IDS env var is not set' do
      stub_env('SNIPPET_IDS' => nil)

      expect { subject }.to raise_error(RuntimeError, 'Please supply the list of ids through the SNIPPET_IDS env var')
    end

    it 'fails if the number of ids provided is higher than the limit' do
      stub_env('LIMIT' => 2)

      expect { subject }.to raise_error(RuntimeError, /The number of ids provided is higher than/)
    end

    it 'fails if the env var LIMIT is invalid' do
      stub_env('LIMIT' => 'foo')

      expect { subject }.to raise_error(RuntimeError, 'Invalid limit value')
    end

    it 'fails if the ids are invalid' do
      stub_env('SNIPPET_IDS' => '1,2,a')

      expect { subject }.to raise_error(RuntimeError, 'Invalid id provided')
    end

    it 'fails if the snippet background migration is running' do
      Sidekiq::Testing.disable! do
        BackgroundMigrationWorker.perform_in(180, 'BackfillSnippetRepositories', [non_migrated.first.id, non_migrated.last.id])

        Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
          expect(Sidekiq::ScheduledSet.new).to be_one
        end

        expect { subject }.to raise_error(RuntimeError, /There are already snippet migrations running/)

        Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
          Sidekiq::ScheduledSet.new.clear
        end
      end
    end
  end

  describe 'migration_status' do
    subject { run_rake_task('gitlab:snippets:migration_status') }

    it 'looks up the appropriate shard' do
      expect(Gitlab::SidekiqConfig::WorkerRouter.global).to receive(:store).and_call_original
      # the default config/gitlab.yml gives nil for all workers
      expect(Gitlab::SidekiqSharding::Router).to receive(:get_shard_instance).with(nil).and_call_original

      subject
    end

    it 'returns a message when the background migration is not running' do
      expect { subject }.to output("There are no snippet migrations running\n").to_stdout
    end

    it 'returns a message saying that the background migration is running' do
      Sidekiq::Testing.disable! do
        BackgroundMigrationWorker.perform_in(180, 'BackfillSnippetRepositories', [non_migrated.first.id, non_migrated.last.id])
        Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
          expect(Sidekiq::ScheduledSet.new).to be_one
        end

        expect { subject }.to output("There are snippet migrations running\n").to_stdout

        Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
          Sidekiq::ScheduledSet.new.clear
        end
      end
    end
  end

  describe 'list_non_migrated' do
    subject { run_rake_task('gitlab:snippets:list_non_migrated') }

    it 'returns a message if all snippets are migrated' do
      expect { subject }.to output("All snippets have been successfully migrated\n").to_stdout
    end

    context 'when there are still non migrated snippets' do
      let!(:non_migrated) { create_list(:personal_snippet, 3, author: user) }

      it 'returns a message returning the non migrated snippets ids' do
        expect { subject }.to output(/#{non_migrated_ids}/).to_stdout
      end

      it 'returns as many snippet ids as the limit set' do
        stub_env('LIMIT' => 1)

        expect { subject }.to output(/#{non_migrated_ids[0]}/).to_stdout
      end
    end
  end
end
