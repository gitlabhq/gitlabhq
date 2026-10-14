# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Instrumentation::Authz, :request_store, feature_category: :permissions do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private) }

  describe '.measure' do
    it 'returns the block result' do
      expect(described_class.measure { :result }).to eq(:result)
    end

    it 'does not count calls nested in a measured call' do
      described_class.measure { described_class.measure { nil } }

      expect(described_class.payload).to include(authz_call_count: 1)
    end

    it 'totals time and queries across calls' do
      described_class.measure { User.find(user.id) }
      described_class.measure { Project.find(project.id) }

      expect(described_class.payload).to include(
        authz_call_count: 2,
        authz_duration_s: be > 0,
        authz_db_count: 2,
        authz_db_cached_count: 0,
        authz_db_duration_s: be > 0
      )
    end

    it 'counts cached queries in both the query and cached query totals' do
      ApplicationRecord.cache do
        described_class.measure do
          User.where(id: user.id).to_a
          User.where(id: user.id).to_a
        end
      end

      expect(described_class.payload).to include(authz_db_count: 2, authz_db_cached_count: 1)
    end

    it 'measures later calls after a block raises' do
      expect { described_class.measure { raise ArgumentError } }.to raise_error(ArgumentError)

      described_class.measure { nil }

      expect(described_class.payload).to include(authz_call_count: 2)
    end

    it 'only runs the block without a request store' do
      allow(Gitlab::SafeRequestStore).to receive(:active?).and_return(false)

      expect(described_class.measure { :result }).to eq(:result)
      expect(Gitlab::SafeRequestStore[described_class::STATS]).to be_nil
    end
  end

  describe '.payload' do
    it 'is empty when nothing was measured' do
      expect(described_class.payload).to eq({})
    end
  end

  describe 'measured call sites' do
    it 'measures a permission check once, including the access lookup inside it' do
      Ability.allowed?(user, :read_project, project)

      expect(described_class.payload).to include(authz_call_count: 1)
    end

    it 'measures a project access lookup' do
      project.team.max_member_access_for_user(user)

      expect(described_class.payload).to include(authz_call_count: 1)
    end

    it 'measures a user access lookup for projects' do
      user.max_member_access_for_project_ids([project.id])

      expect(described_class.payload).to include(authz_call_count: 1)
    end

    it 'measures the access level preloader' do
      Preloaders::UserMaxAccessLevelInProjectsPreloader.new([project], user).execute

      expect(described_class.payload).to include(authz_call_count: 1)
    end
  end
end
