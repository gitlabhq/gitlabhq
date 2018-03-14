# encoding: utf-8

require 'spec_helper'
require Rails.root.join('db', 'migrate', '20161226122833_remove_dot_git_from_usernames.rb')

describe RemoveDotGitFromUsernames do
  let(:user) { create(:user) }
  let(:migration) { described_class.new }

  describe '#up' do
    before do
      update_namespace(user, 'test.git')
    end

    it 'renames user with .git in username' do
      migration.up

      expect(user.reload.username).to eq('test_git')
      expect(user.namespace.reload.path).to eq('test_git')
      expect(user.namespace.route.path).to eq('test_git')
    end
  end

  context 'when new path exists already' do
    describe '#up' do
      let(:user2) { create(:user) }

      before do
        update_namespace(user, 'test.git')
        update_namespace(user2, 'test_git')

        default_hash = Gitlab.config.repositories.storages.default.to_h
        default_hash['path'] = 'tmp/tests/custom_repositories'
        storages = { 'default' => Gitlab::GitalyClient::StorageSettings.new(default_hash) }

        allow(Gitlab.config.repositories).to receive(:storages).and_return(storages)
        allow(migration).to receive(:route_exists?).with('test_git').and_return(true)
        allow(migration).to receive(:route_exists?).with('test_git1').and_return(false)
      end

      it 'renames user with .git in username' do
        migration.up

        expect(user.reload.username).to eq('test_git1')
        expect(user.namespace.reload.path).to eq('test_git1')
        expect(user.namespace.route.path).to eq('test_git1')
      end
    end
  end

  def update_namespace(user, path)
    namespace = user.namespace
    namespace.path = path
    namespace.save!(validate: false)

    user.update_column(:username, path)
  end
end
