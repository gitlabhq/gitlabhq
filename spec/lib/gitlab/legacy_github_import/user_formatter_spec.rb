require 'spec_helper'

describe Gitlab::LegacyGithubImport::UserFormatter do
  let(:client) { double }
  let(:octocat) { double(id: 123456, login: 'octocat', email: 'octocat@example.com') }

  subject(:user) { described_class.new(client, octocat) }

  before do
    allow(client).to receive(:user).and_return(octocat)
  end

  describe '#gitlab_id' do
    context 'when GitHub user is a GitLab user' do
      it 'return GitLab user id when user associated their account with GitHub' do
        gl_user = create(:omniauth_user, extern_uid: octocat.id, provider: 'github')

        expect(user.gitlab_id).to eq gl_user.id
      end

      it 'returns GitLab user id when user primary email matches GitHub email' do
        gl_user = create(:user, email: octocat.email)

        expect(user.gitlab_id).to eq gl_user.id
      end

      it 'returns GitLab user id when any of user linked emails matches GitHub email' do
        gl_user = create(:user, email: 'johndoe@example.com')
        create(:email, user: gl_user, email: octocat.email)

        expect(user.gitlab_id).to eq gl_user.id
      end
    end

    it 'returns nil when GitHub user is not a GitLab user' do
      expect(user.gitlab_id).to be_nil
    end
  end
end
