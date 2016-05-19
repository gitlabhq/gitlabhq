require 'spec_helper'

describe Gitlab::GithubImport::CommentFormatter, lib: true do
  let(:project) { create(:project) }
  let(:octocat) { double(id: 123456, login: 'octocat') }
  let(:created_at) { DateTime.strptime('2013-04-10T20:09:31Z') }
  let(:updated_at) { DateTime.strptime('2014-03-03T18:58:10Z') }
  let(:base) do
    {
      body: "I'm having a problem with this.",
      user: octocat,
      commit_id: nil,
      diff_hunk: nil,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  subject(:comment) { described_class.new(project, raw)}

  describe '#attributes' do
    context 'when do not reference a portion of the diff' do
      let(:raw) { double(base) }

      it 'returns formatted attributes' do
        expected = {
          project: project,
          note: "*Created by: octocat*\n\nI'm having a problem with this.",
          commit_id: nil,
          line_code: nil,
          author_id: project.creator_id,
          created_at: created_at,
          updated_at: updated_at
        }

        expect(comment.attributes).to eq(expected)
      end
    end

    context 'when on a portion of the diff' do
      let(:diff) do
        {
          body: 'Great stuff',
          commit_id: '6dcb09b5b57875f334f61aebed695e2e4193db5e',
          diff_hunk: "@@ -1,5 +1,9 @@\n class User\n   def name\n-    'John Doe'\n+    'Jane Doe'",
          path: 'file1.txt'
        }
      end

      let(:raw) { double(base.merge(diff)) }

      it 'returns formatted attributes' do
        expected = {
          project: project,
          note: "*Created by: octocat*\n\nGreat stuff",
          commit_id: '6dcb09b5b57875f334f61aebed695e2e4193db5e',
          line_code: 'ce1be0ff4065a6e9415095c95f25f47a633cef2b_4_3',
          author_id: project.creator_id,
          created_at: created_at,
          updated_at: updated_at
        }

        expect(comment.attributes).to eq(expected)
      end
    end

    context 'when author is a GitLab user' do
      let(:raw) { double(base.merge(user: octocat)) }

      it 'returns GitLab user id as author_id' do
        gl_user = create(:omniauth_user, extern_uid: octocat.id, provider: 'github')
        expect(comment.attributes.fetch(:author_id)).to eq gl_user.id
      end
    end
  end
end
