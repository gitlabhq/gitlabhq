# encoding: utf-8

require 'spec_helper'
require Rails.root.join('db', 'migrate', '20161226122833_remove_dot_git_from_usernames.rb')

describe RemoveDotGitFromUsernames do
  let(:user) { create(:user) }

  describe '#up' do
    let(:migration) { described_class.new }

    before do
      namespace = user.namespace
      namespace.path = 'test.git'
      namespace.save!(validate: false)

      user.username = 'test.git'
      user.save!(validate: false)
    end

    it 'renames user with .git in username' do
      migration.up

      expect(user.reload.username).to eq('test_git')
      expect(user.namespace.reload.path).to eq('test_git')
      expect(user.namespace.route.path).to eq('test_git')
    end
  end
end
