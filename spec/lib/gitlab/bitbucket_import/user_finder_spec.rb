# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::UserFinder, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:identity) { create(:identity, user: user, extern_uid: '{123}', provider: :bitbucket) }
  let(:created_id) { 1 }
  let(:project) { instance_double(Project, creator_id: created_id, id: 1) }
  let(:author_uuid) { '{123}' }
  let(:cache_key) do
    format(
      described_class::USER_ID_FOR_AUTHOR_CACHE_KEY,
      project_id: project.id,
      author_uuid: author_uuid
    )
  end

  subject(:user_finder) { described_class.new(project) }

  describe '#find_user_id' do
    it 'returns the user id' do
      expect(User).to receive(:by_provider_and_extern_uid).and_call_original.once

      expect(user_finder.find_user_id(author_uuid)).to eq(user.id)
      expect(user_finder.find_user_id(author_uuid)).to eq(user.id)
    end

    context 'when the id is cached' do
      before do
        Gitlab::Cache::Import::Caching.write(cache_key, user.id)
      end

      it 'does not attempt to find the user' do
        expect(User).not_to receive(:by_provider_and_extern_uid)

        expect(user_finder.find_user_id(author_uuid)).to eq(user.id)
      end
    end

    context 'when -1 is cached' do
      before do
        Gitlab::Cache::Import::Caching.write(cache_key, -1)
      end

      it 'does not attempt to find the user and returns nil' do
        expect(User).not_to receive(:by_provider_and_extern_uid)

        expect(user_finder.find_user_id(author_uuid)).to be_nil
      end
    end

    context 'when the user does not have a matching bitbucket identity' do
      before do
        identity.update!(provider: :github)
      end

      it 'returns nil' do
        expect(user_finder.find_user_id(author_uuid)).to be_nil
      end
    end
  end

  describe '#gitlab_user_id' do
    context 'when find_user_id returns a user' do
      it 'returns the user id' do
        expect(user_finder.gitlab_user_id(project, author_uuid)).to eq(user.id)
      end
    end

    context 'when find_user_id does not return a user' do
      before do
        allow(user_finder).to receive(:find_user_id).and_return(nil)
      end

      it 'returns the project creator' do
        expect(user_finder.gitlab_user_id(project, author_uuid)).to eq(created_id)
      end
    end
  end
end
