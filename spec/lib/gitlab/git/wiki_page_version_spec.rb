# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::WikiPageVersion do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user) { create(:user, username: 'someone') }

  describe '#author' do
    subject(:author) { described_class.new(commit, nil).author }

    context 'user exists in gitlab' do
      let(:commit) { create(:commit, project: project, author: user) }

      it 'returns the user' do
        expect(author).to eq user
      end
    end

    context 'user does not exist in gitlab' do
      let(:commit) { create(:commit, project: project, author_email: "someone@somewebsite.com") }

      it 'returns nil' do
        expect(author).to be_nil
      end
    end
  end
end
