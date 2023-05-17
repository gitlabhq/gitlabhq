# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LegacyGithubImport::UserFormatter do
  let(:client) { double }
  let(:octocat) { { id: 123456, login: 'octocat', email: 'octocat@example.com' } }
  let(:gitea_ghost) { { id: -1, login: 'Ghost', email: '' } }

  describe '#gitlab_id' do
    subject(:user) { described_class.new(client, octocat) }

    before do
      allow(client).to receive(:user).and_return(octocat)
    end

    context 'when GitHub user is a GitLab user' do
      it 'return GitLab user id when user associated their account with GitHub' do
        gl_user = create(:omniauth_user, extern_uid: octocat[:id], provider: 'github')

        expect(user.gitlab_id).to eq gl_user.id
      end

      it 'returns GitLab user id when user confirmed primary email matches GitHub email' do
        gl_user = create(:user, email: octocat[:email])

        expect(user.gitlab_id).to eq gl_user.id
      end

      it 'returns GitLab user id when user unconfirmed primary email matches GitHub email' do
        gl_user = create(:user, :unconfirmed, email: octocat[:email])

        expect(user.gitlab_id).to eq gl_user.id
      end

      it 'returns GitLab user id when user confirmed secondary email matches GitHub email' do
        gl_user = create(:user, email: 'johndoe@example.com')
        create(:email, :confirmed, user: gl_user, email: octocat[:email])

        expect(user.gitlab_id).to eq gl_user.id
      end

      it 'returns nil when user unconfirmed secondary email matches GitHub email' do
        gl_user = create(:user, email: 'johndoe@example.com')
        create(:email, user: gl_user, email: octocat[:email])

        expect(user.gitlab_id).to be_nil
      end
    end

    it 'returns nil when GitHub user is not a GitLab user' do
      expect(user.gitlab_id).to be_nil
    end
  end

  describe '.email' do
    subject(:user) { described_class.new(client, gitea_ghost) }

    before do
      allow(client).to receive(:user).and_return(gitea_ghost)
    end

    it 'assigns a dummy email address when user is a Ghost gitea user' do
      expect(subject.send(:email)).to eq described_class::GITEA_GHOST_EMAIL
    end
  end
end
