# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::UserFinder, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let_it_be(:user_namespace) { create(:namespace) }
  let_it_be_with_reload(:project) do
    create(
      :project,
      :in_group,
      import_type: 'github',
      import_url: 'https://github.com/user/repo.git'
    )
  end

  let_it_be(:ghost_user) { Users::Internal.in_organization(project.organization).ghost }

  let(:client) { instance_double(Gitlab::GithubImport::Client) }
  let(:settings) { Gitlab::GithubImport::Settings.new }

  subject(:finder) { described_class.new(project, client) }

  describe '#author_id_for' do
    context 'with default author_key' do
      it 'returns the user ID for the author of an object' do
        user = { id: 4, login: 'kittens' }
        note = { author: user }

        expect(finder).to receive(:user_id_for).with(user, ghost: true).and_return(42)

        expect(finder.author_id_for(note)).to eq([42, true])
      end

      it 'returns the ID of the ghost id if no user ID could be found' do
        user = { id: 4, login: 'kittens' }
        note = { author: user }

        expect(finder).to receive(:user_id_for).with(user, ghost: true).and_return(ghost_user.id)

        expect(finder.author_id_for(note)).to eq([ghost_user.id, true])
      end

      it 'returns the ID of the ghost user when the object has no user' do
        note = { author: nil }

        expect(finder.author_id_for(note)).to eq([ghost_user.id, true])
      end

      it 'returns the ID of the ghost user when the given object is nil' do
        expect(finder.author_id_for(nil)).to eq([ghost_user.id, true])
      end
    end

    context 'with a non-default author_key' do
      let(:user) { { id: 4, login: 'kittens' } }

      shared_examples 'user ID finder' do |author_key|
        it 'returns the user ID for an object' do
          expect(finder).to receive(:user_id_for).with(user, ghost: true).and_return(42)

          expect(finder.author_id_for(issue_event, author_key: author_key)).to eq([42, true])
        end
      end

      context 'when the author_key parameter is :actor' do
        let(:issue_event) { { actor: user } }

        it_behaves_like 'user ID finder', :actor
      end

      context 'when the author_key parameter is :review_requester' do
        let(:issue_event) { { review_requester: user } }

        it_behaves_like 'user ID finder', :review_requester
      end
    end
  end

  describe '#user_id_for' do
    context 'when passed `nil`' do
      it 'returns the ghost user id' do
        expect(finder.user_id_for(nil)).to eq(ghost_user.id)
      end

      context 'when `ghost:` is false' do
        it 'returns nil' do
          expect(finder.user_id_for(nil, ghost: false)).to be_nil
        end
      end
    end

    context 'when user is GitHub ghost user' do
      it 'returns the ghost user id' do
        expect(finder.user_id_for({ login: 'ghost' })).to eq(ghost_user.id)
      end

      context 'when `ghost:` is false' do
        it 'returns nil' do
          expect(finder.user_id_for({ login: 'ghost' }, ghost: false)).to be_nil
        end
      end
    end

    context 'when user mapping is enabled' do
      let_it_be(:source_user) do
        create(:import_source_user,
          namespace: project.root_ancestor,
          source_user_identifier: '7',
          source_hostname: 'https://github.com'
        )
      end

      it 'returns the mapped_user_id of source user with matching user identifier' do
        user = { id: 7, login: 'anything' }

        expect(finder.user_id_for(user)).to eq(source_user.mapped_user_id)
      end

      it 'creates a new source user when user identifier does not match' do
        user = { id: 6, login: 'anything' }

        allow(client).to receive(:user).and_return({ name: 'Source name' })

        expect { finder.user_id_for(user) }.to change { Import::SourceUser.count }.by(1)
        expect(finder.user_id_for(user)).not_to eq(source_user.mapped_user_id)
      end

      context 'when the project is imported into a personal namespace' do
        before do
          project.update!(namespace: user_namespace)
        end

        it 'returns the user namespace owner id' do
          user = { id: 6, login: 'anything' }

          allow(client).to receive(:user).and_return({ name: 'Source name' })

          expect { finder.user_id_for(user) }.not_to change { Import::SourceUser.count }
          expect(finder.user_id_for(user)).to eq(user_namespace.owner_id)
        end
      end
    end
  end

  describe '#source_user' do
    context 'when source user exists' do
      let!(:source_user) do
        create(:import_source_user,
          namespace: project.root_ancestor,
          source_user_identifier: '7',
          source_hostname: 'https://github.com'
        )
      end

      it 'returns the existing source user' do
        user = { id: 7, login: 'kittens' }

        expect(finder.source_user(user)).to eq(source_user)
      end
    end

    context 'when source user does not exist' do
      it 'fetches the user source name from GitHub and creates a new source user' do
        user = { id: 7, login: 'kittens' }

        expect(client).to receive(:user).with('kittens').and_return({ name: 'Source name' })
        expect { finder.source_user(user) }.to change { Import::SourceUser.count }.by(1)
        expect(Import::SourceUser.last).to have_attributes(
          source_name: 'Source name',
          source_username: 'kittens',
          source_user_identifier: '7'
        )
      end

      context 'when GitHub user does not exist' do
        before do
          allow(client).to receive(:user).with('Copilot').and_raise(Octokit::NotFound)
        end

        it 'creates a new source user, logs, and sets the `source_name` to be the username' do
          user = { id: 7, login: 'Copilot' }

          expect(Gitlab::GithubImport::Logger).to receive(:info).with(hash_including(
            message: include('GitHub user not found.'),
            username: 'Copilot',
            Labkit::Fields::GL_ORGANIZATION_ID => project.organization_id
          ))
          expect { finder.source_user(user) }.to change { Import::SourceUser.count }.by(1)
          expect(Import::SourceUser.last).to have_attributes(
            source_name: 'Copilot',
            source_username: 'Copilot',
            source_user_identifier: '7'
          )
        end
      end
    end
  end

  describe '#fetch_source_name_from_github' do
    let(:username) { 'kittens' }
    let(:lease_name) { "gitlab:github_import:user_finder:#{username}" }

    subject(:fetch_source_name_from_github) { finder.fetch_source_name_from_github(username) }

    it 'fetches user name from GitHub and caches it' do
      expect(finder).to receive(:in_lock).with(lease_name, sleep_sec: 0.2.seconds, retries: 30).and_call_original
      expect(client).to receive(:user).with(username).and_return({ name: 'Source name' })
      expect(Gitlab::Cache::Import::Caching).to receive(:write)
        .with(format(described_class::SOURCE_NAME_CACHE_KEY, project: project.id, username: username), 'Source name')

      expect(fetch_source_name_from_github).to eq('Source name')
    end

    context 'when lock is retried' do
      it 'returns the cached value' do
        Gitlab::Cache::Import::Caching.write(
          format(described_class::SOURCE_NAME_CACHE_KEY, project: project.id, username: username), 'Source name'
        )

        expect(finder).to receive(:in_lock).and_yield(true)

        expect(fetch_source_name_from_github).to eq('Source name')
      end
    end

    context 'when no name is returned' do
      it 'returns the username' do
        expect(client).to receive(:user).with(username).and_return({})

        expect(fetch_source_name_from_github).to eq(username)
      end
    end
  end

  describe '#source_user_accepted?' do
    let_it_be(:user) { { id: 7, login: 'anything' } }
    let_it_be_with_reload(:source_user) do
      create(
        :import_source_user, :awaiting_approval,
        namespace: project.root_ancestor,
        source_hostname: 'https://github.com',
        import_type: project.import_type,
        source_user_identifier: user[:id]
      )
    end

    it 'returns true when the associated source user has an accepted status' do
      source_user.accept!

      expect(finder.source_user_accepted?(user)).to be(true)
    end

    it 'returns false when the associated source user does not have an accepted status' do
      expect(finder.source_user_accepted?(user)).to be(false)
    end

    context 'when the project is imported into a personal namespace' do
      before do
        project.update!(namespace: user_namespace)
      end

      # User contributions are assigned directly to the namespace owner, effectively behaving as accepted source users
      it 'returns true' do
        expect(finder.source_user_accepted?(user)).to be(true)
      end
    end
  end
end
