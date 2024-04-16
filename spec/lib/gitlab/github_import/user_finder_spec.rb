# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::UserFinder, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let(:project) do
    create(
      :project,
      import_type: 'github',
      import_url: 'https://api.github.com/user/repo'
    )
  end

  let(:client) { double(:client) }
  let(:finder) { described_class.new(project, client) }

  describe '#author_id_for' do
    context 'with default author_key' do
      it 'returns the user ID for the author of an object' do
        user = { id: 4, login: 'kittens' }
        note = { author: user }

        expect(finder).to receive(:user_id_for).with(user).and_return(42)

        expect(finder.author_id_for(note)).to eq([42, true])
      end

      it 'returns the ID of the project creator if no user ID could be found' do
        user = { id: 4, login: 'kittens' }
        note = { author: user }

        expect(finder).to receive(:user_id_for).with(user).and_return(nil)

        expect(finder.author_id_for(note)).to eq([project.creator_id, false])
      end

      it 'returns the ID of the ghost user when the object has no user' do
        note = { author: nil }

        expect(finder.author_id_for(note)).to eq([Users::Internal.ghost.id, true])
      end

      it 'returns the ID of the ghost user when the given object is nil' do
        expect(finder.author_id_for(nil)).to eq([Users::Internal.ghost.id, true])
      end
    end

    context 'with a non-default author_key' do
      let(:user) { { id: 4, login: 'kittens' } }

      shared_examples 'user ID finder' do |author_key|
        it 'returns the user ID for an object' do
          expect(finder).to receive(:user_id_for).with(user).and_return(42)

          expect(finder.author_id_for(issue_event, author_key: author_key)).to eq([42, true])
        end
      end

      context 'when the author_key parameter is :actor' do
        let(:issue_event) { { actor: user } }

        it_behaves_like 'user ID finder', :actor
      end

      context 'when the author_key parameter is :assignee' do
        let(:issue_event) { { assignee: user } }

        it_behaves_like 'user ID finder', :assignee
      end

      context 'when the author_key parameter is :requested_reviewer' do
        let(:issue_event) { { requested_reviewer: user } }

        it_behaves_like 'user ID finder', :requested_reviewer
      end

      context 'when the author_key parameter is :review_requester' do
        let(:issue_event) { { review_requester: user } }

        it_behaves_like 'user ID finder', :review_requester
      end
    end
  end

  describe '#assignee_id_for' do
    it 'returns the user ID for the assignee of an issuable' do
      user = { id: 4, login: 'kittens' }
      issue = { assignee: user }

      expect(finder).to receive(:user_id_for).with(user).and_return(42)
      expect(finder.assignee_id_for(issue)).to eq(42)
    end

    it 'returns nil if the issuable does not have an assignee' do
      issue = { assignee: nil }

      expect(finder).not_to receive(:user_id_for)
      expect(finder.assignee_id_for(issue)).to be_nil
    end
  end

  describe '#user_id_for' do
    it 'returns the user ID for the given user' do
      user = { id: 4, login: 'kittens' }

      expect(finder).to receive(:find).with(user[:id], user[:login]).and_return(42)
      expect(finder.user_id_for(user)).to eq(42)
    end

    it 'does not fail with empty input' do
      expect(finder.user_id_for(nil)).to eq(nil)
    end
  end

  describe '#find' do
    let(:user) { create(:user) }

    before do
      allow(finder).to receive(:email_for_github_username)
        .and_return(user.email)
    end

    context 'without a cache' do
      before do
        allow(finder).to receive(:find_from_cache).and_return([false, nil])
        expect(finder).to receive(:find_id_from_database).and_call_original
      end

      it 'finds a GitLab user for a GitHub user ID' do
        user.identities.create!(provider: :github, extern_uid: 42)

        expect(finder.find(42, user.username)).to eq(user.id)
      end

      it 'finds a GitLab user for a GitHub Email address' do
        expect(finder.find(42, user.username)).to eq(user.id)
      end
    end

    context 'with a cache' do
      it 'returns the cached user ID' do
        expect(finder).to receive(:find_from_cache).and_return([true, user.id])
        expect(finder).not_to receive(:find_id_from_database)

        expect(finder.find(42, user.username)).to eq(user.id)
      end

      it 'does not query the database if the cache key exists but is empty' do
        expect(finder).to receive(:find_from_cache).and_return([true, nil])
        expect(finder).not_to receive(:find_id_from_database)

        expect(finder.find(42, user.username)).to be_nil
      end
    end
  end

  describe '#find_from_cache' do
    it 'retrieves a GitLab user ID for a GitHub user ID' do
      expect(finder)
        .to receive(:cached_id_for_github_id)
        .with(42)
        .and_return([true, 4])

      expect(finder.find_from_cache(42)).to eq([true, 4])
    end

    it 'retrieves a GitLab user ID for a GitHub Email address' do
      email = 'kittens@example.com'

      expect(finder)
        .to receive(:cached_id_for_github_id)
        .with(42)
        .and_return([false, nil])

      expect(finder)
        .to receive(:cached_id_for_github_email)
        .with(email)
        .and_return([true, 4])

      expect(finder.find_from_cache(42, email)).to eq([true, 4])
    end

    it 'does not query the cache for an Email address when none is given' do
      expect(finder)
        .to receive(:cached_id_for_github_id)
        .with(42)
        .and_return([false, nil])

      expect(finder).not_to receive(:cached_id_for_github_id)

      expect(finder.find_from_cache(42)).to eq([false])
    end
  end

  describe '#find_id_from_database' do
    let(:user) { create(:user) }

    it 'returns the GitLab user ID for a GitHub user ID' do
      user.identities.create!(provider: :github, extern_uid: 42)

      expect(finder.find_id_from_database(42, user.email)).to eq(user.id)
    end

    it 'returns the GitLab user ID for a GitHub Email address' do
      expect(finder.find_id_from_database(42, user.email)).to eq(user.id)
    end
  end

  describe '#email_for_github_username' do
    let(:email) { 'kittens@example.com' }
    let(:username) { 'kittens' }
    let(:user) { {} }
    let(:etag) { 'etag' }
    let(:lease_name) { "gitlab:github_import:user_finder:#{username}" }
    let(:cache_key) { described_class::EMAIL_FOR_USERNAME_CACHE_KEY % username }
    let(:etag_cache_key) { described_class::USERNAME_ETAG_CACHE_KEY % username }
    let(:email_fetched_for_project_key) do
      format(described_class::EMAIL_FETCHED_FOR_PROJECT_CACHE_KEY, project: project.id, username: username)
    end

    subject(:email_for_github_username) { finder.email_for_github_username(username) }

    shared_examples 'returns and caches the email' do
      it 'returns the email' do
        expect(email_for_github_username).to eq(email)
      end

      it 'caches the email and expires the etag and project check caches' do
        expect(Gitlab::Cache::Import::Caching).to receive(:write).with(cache_key, email).once
        expect(Gitlab::Cache::Import::Caching).to receive(:expire).with(etag_cache_key, 0).once
        expect(Gitlab::Cache::Import::Caching).to receive(:expire).with(email_fetched_for_project_key, 0).once

        email_for_github_username
        email_for_github_username
      end
    end

    shared_examples 'returns nil and caches a negative lookup' do
      it 'returns nil' do
        expect(email_for_github_username).to be_nil
      end

      it 'caches a blank email and marks the project as checked' do
        expect(Gitlab::Cache::Import::Caching).to receive(:write).with(cache_key, '').once
        expect(Gitlab::Cache::Import::Caching).not_to receive(:write).with(etag_cache_key, anything)
        expect(Gitlab::Cache::Import::Caching).to receive(:write).with(email_fetched_for_project_key, 1).once

        email_for_github_username
        email_for_github_username
      end
    end

    shared_examples 'does not change caches' do
      it 'does not write to any of the caches' do
        expect(Gitlab::Cache::Import::Caching).not_to receive(:write).with(cache_key, anything)
        expect(Gitlab::Cache::Import::Caching).not_to receive(:write).with(etag_cache_key, anything)
        expect(Gitlab::Cache::Import::Caching).not_to receive(:write).with(email_fetched_for_project_key, anything)

        email_for_github_username
        email_for_github_username
      end
    end

    shared_examples 'a user resource not found on GitHub' do
      before do
        allow(client).to receive(:user).and_raise(::Octokit::NotFound)
      end

      it 'returns nil' do
        expect(email_for_github_username).to be_nil
      end

      it 'caches a blank email' do
        expect(Gitlab::Cache::Import::Caching).to receive(:write).with(cache_key, '').once
        expect(Gitlab::Cache::Import::Caching).not_to receive(:write).with(etag_cache_key, anything)
        expect(Gitlab::Cache::Import::Caching).not_to receive(:write).with(email_fetched_for_project_key, anything)

        email_for_github_username
        email_for_github_username
      end
    end

    context 'when the email is cached' do
      before do
        Gitlab::Cache::Import::Caching.write(cache_key, email)
      end

      it 'returns the email from the cache' do
        expect(email_for_github_username).to eq(email)
      end

      it 'does not make a rate-limited API call' do
        expect(client).not_to receive(:user).with(username, { headers: {} })

        email_for_github_username
        email_for_github_username
      end
    end

    context 'when the email cache is nil' do
      context 'if the email has not been checked for the project' do
        context 'if the cached etag is nil' do
          before do
            allow(client).to receive_message_chain(:octokit, :last_response, :headers).and_return({ etag: etag })
          end

          it 'makes an API call' do
            expect(client).to receive(:user).with(username, { headers: {} }).and_return({ email: email }).once
            expect(finder).to receive(:in_lock).with(
              lease_name, sleep_sec: 0.2.seconds, retries: 30
            ).and_call_original

            email_for_github_username
          end

          context 'when github_import_lock_user_finder feature flag is disabled' do
            before do
              stub_feature_flags(github_import_lock_user_finder: false)
            end

            it 'does not lock the finder' do
              expect(finder).not_to receive(:in_lock)
              expect(client).to receive(:user)

              email_for_github_username
            end
          end

          context 'if the response contains an email' do
            before do
              allow(client).to receive(:user).and_return({ email: email })
            end

            it_behaves_like 'returns and caches the email'

            context 'when retried' do
              before do
                allow(finder).to receive(:in_lock).and_yield(true)
              end

              it_behaves_like 'returns and caches the email'
            end
          end

          context 'if the response does not contain an email' do
            before do
              allow(client).to receive(:user).and_return({})
            end

            it 'returns nil' do
              expect(email_for_github_username).to be_nil
            end

            it 'caches a blank email and etag and marks the project as checked' do
              expect(Gitlab::Cache::Import::Caching).to receive(:write).with(cache_key, '').once
              expect(Gitlab::Cache::Import::Caching).to receive(:write).with(etag_cache_key, etag).once
              expect(Gitlab::Cache::Import::Caching).to receive(:write).with(email_fetched_for_project_key, 1).once

              email_for_github_username
              email_for_github_username
            end
          end
        end

        context 'if the cached etag is not nil' do
          before do
            Gitlab::Cache::Import::Caching.write(etag_cache_key, etag)
          end

          it 'makes a non-rate-limited API call' do
            expect(client).to receive(:user).with(username, { headers: { 'If-None-Match' => etag } }).once
            expect(finder).to receive(:in_lock).with(
              lease_name, sleep_sec: 0.2.seconds, retries: 30
            ).and_call_original

            email_for_github_username
          end

          context 'if the response contains an email' do
            before do
              allow(client).to receive(:user).and_return({ email: email })
            end

            it_behaves_like 'returns and caches the email'
          end

          context 'if the response does not contain an email' do
            before do
              allow(client).to receive(:user).and_return({})
            end

            it_behaves_like 'returns nil and caches a negative lookup'
          end

          context 'if the response is nil' do
            before do
              allow(client).to receive(:user).and_return(nil)
            end

            it 'returns nil' do
              expect(email_for_github_username).to be_nil
            end

            it 'marks the project as checked' do
              expect(Gitlab::Cache::Import::Caching).not_to receive(:write).with(cache_key, anything)
              expect(Gitlab::Cache::Import::Caching).not_to receive(:write).with(etag_cache_key, anything)
              expect(Gitlab::Cache::Import::Caching).to receive(:write).with(email_fetched_for_project_key, 1).once

              email_for_github_username
              email_for_github_username
            end
          end
        end
      end

      context 'if the email has been checked for the project' do
        before do
          Gitlab::Cache::Import::Caching.write(email_fetched_for_project_key, 1)
        end

        it 'returns nil' do
          expect(email_for_github_username).to be_nil
        end

        it_behaves_like 'does not change caches'
      end

      it_behaves_like 'a user resource not found on GitHub'
    end

    context 'when the email cache is blank' do
      before do
        Gitlab::Cache::Import::Caching.write(cache_key, '')
      end

      context 'if the email has not been checked for the project' do
        context 'if the cached etag is not nil' do
          before do
            Gitlab::Cache::Import::Caching.write(etag_cache_key, etag)
          end

          it 'makes a non-rate-limited API call' do
            expect(client).to receive(:user).with(username, { headers: { 'If-None-Match' => etag } }).once
            expect(finder).to receive(:in_lock).with(
              lease_name, sleep_sec: 0.2.seconds, retries: 30
            ).and_call_original

            email_for_github_username
          end

          context 'if the response contains an email' do
            before do
              allow(client).to receive(:user).and_return({ email: email })
            end

            it_behaves_like 'returns and caches the email'
          end

          context 'if the response does not contain an email' do
            before do
              allow(client).to receive(:user).and_return({})
            end

            it_behaves_like 'returns nil and caches a negative lookup'
          end

          context 'if the response is nil' do
            before do
              allow(client).to receive(:user).and_return(nil)
            end

            it_behaves_like 'returns nil and caches a negative lookup'
          end

          it_behaves_like 'a user resource not found on GitHub'
        end

        context 'if the cached etag is nil' do
          context 'when lock was executed by another process and an email was fetched' do
            it 'does not fetch user detail' do
              expect(finder).to receive(:read_email_from_cache).ordered.and_return('')
              expect(finder).to receive(:read_email_from_cache).ordered.and_return(email)
              expect(finder).to receive(:in_lock).and_yield(true)
              expect(client).not_to receive(:user)

              email_for_github_username
            end
          end

          context 'when lock was executed by another process and an email in cache is still blank' do
            it 'fetch user detail' do
              expect(finder).to receive(:read_email_from_cache).ordered.and_return('')
              expect(finder).to receive(:read_email_from_cache).ordered.and_return('')
              expect(finder).to receive(:read_etag_from_cache).and_return(etag)
              expect(finder).to receive(:in_lock).and_yield(true)
              expect(client).to receive(:user).with(username, { headers: { 'If-None-Match' => etag } }).once

              email_for_github_username
            end
          end
        end
      end

      context 'if the email has been checked for the project' do
        before do
          Gitlab::Cache::Import::Caching.write(email_fetched_for_project_key, 1)
        end

        it 'returns nil' do
          expect(email_for_github_username).to be_nil
        end

        it_behaves_like 'does not change caches'
      end
    end
  end

  describe '#cached_id_for_github_id' do
    let(:id) { 4 }

    it 'reads a user ID from the cache' do
      Gitlab::Cache::Import::Caching
        .write(described_class::ID_CACHE_KEY % id, 4)

      expect(finder.cached_id_for_github_id(id)).to eq([true, 4])
    end

    it 'reads a non existing cache key' do
      expect(finder.cached_id_for_github_id(id)).to eq([false, nil])
    end
  end

  describe '#cached_id_for_github_email' do
    let(:email) { 'kittens@example.com' }

    it 'reads a user ID from the cache' do
      Gitlab::Cache::Import::Caching
        .write(described_class::ID_FOR_EMAIL_CACHE_KEY % email, 4)

      expect(finder.cached_id_for_github_email(email)).to eq([true, 4])
    end

    it 'reads a non existing cache key' do
      expect(finder.cached_id_for_github_email(email)).to eq([false, nil])
    end
  end

  describe '#id_for_github_id' do
    let(:id) { 4 }

    it 'queries and caches the user ID for a given GitHub ID' do
      expect(finder).to receive(:query_id_for_github_id)
        .with(id)
        .and_return(42)

      expect(Gitlab::Cache::Import::Caching)
        .to receive(:write)
        .with(described_class::ID_CACHE_KEY % id, 42)

      finder.id_for_github_id(id)
    end

    it 'caches a nil value if no ID could be found' do
      expect(finder).to receive(:query_id_for_github_id)
        .with(id)
        .and_return(nil)

      expect(Gitlab::Cache::Import::Caching)
        .to receive(:write)
        .with(described_class::ID_CACHE_KEY % id, nil)

      finder.id_for_github_id(id)
    end

    context 'when importing from github enterprise' do
      let(:project) do
        create(
          :project,
          import_type: 'github',
          import_url: 'https://othergithub.net/user/repo'
        )
      end

      it 'does not look up the user by external id' do
        expect(finder).not_to receive(:query_id_for_github_id)

        expect(Gitlab::Cache::Import::Caching)
          .to receive(:write)
          .with(described_class::ID_CACHE_KEY % id, nil)

        finder.id_for_github_id(id)
      end
    end
  end

  describe '#id_for_github_email' do
    let(:email) { 'kittens@example.com' }

    it 'queries and caches the user ID for a given Email address' do
      expect(finder).to receive(:query_id_for_github_email)
        .with(email)
        .and_return(42)

      expect(Gitlab::Cache::Import::Caching)
        .to receive(:write)
        .with(described_class::ID_FOR_EMAIL_CACHE_KEY % email, 42)

      finder.id_for_github_email(email)
    end

    it 'caches a nil value if no ID could be found' do
      expect(finder).to receive(:query_id_for_github_email)
        .with(email)
        .and_return(nil)

      expect(Gitlab::Cache::Import::Caching)
        .to receive(:write)
        .with(described_class::ID_FOR_EMAIL_CACHE_KEY % email, nil)

      finder.id_for_github_email(email)
    end
  end

  describe '#query_id_for_github_id' do
    it 'returns the ID of the user for the given GitHub user ID' do
      user = create(:user)

      user.identities.create!(provider: :github, extern_uid: '42')

      expect(finder.query_id_for_github_id(42)).to eq(user.id)
    end

    it 'returns nil when no user ID could be found' do
      expect(finder.query_id_for_github_id(42)).to be_nil
    end
  end

  describe '#query_id_for_github_email' do
    it 'returns the ID of the user for the given Email address' do
      user = create(:user, email: 'kittens@example.com')

      expect(finder.query_id_for_github_email(user.email)).to eq(user.id)
    end

    it 'returns nil if no user ID could be found' do
      expect(finder.query_id_for_github_email('kittens@example.com')).to be_nil
    end
  end

  describe '#read_id_from_cache' do
    it 'reads an ID from the cache' do
      Gitlab::Cache::Import::Caching.write('foo', 10)

      expect(finder.read_id_from_cache('foo')).to eq([true, 10])
    end

    it 'reads a cache key with an empty value' do
      Gitlab::Cache::Import::Caching.write('foo', nil)

      expect(finder.read_id_from_cache('foo')).to eq([true, nil])
    end

    it 'reads a cache key that does not exist' do
      expect(finder.read_id_from_cache('foo')).to eq([false, nil])
    end
  end
end
