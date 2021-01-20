# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::WikiPageVersion do
  let_it_be(:project) { create(:project, :public, :repository) }
  let(:user) { create(:user, username: 'someone') }

  describe '#author_url' do
    subject(:author_url) { described_class.new(commit, nil).author_url }

    context 'user exists in gitlab' do
      let(:commit) { create(:commit, project: project, author: user) }

      it 'returns the profile link of the user' do
        expect(author_url).to eq('http://localhost/someone')
      end
    end

    context 'user does not exist in gitlab' do
      let(:commit) { create(:commit, project: project, author_email: "someone@somewebsite.com") }

      it 'returns a mailto: url' do
        expect(author_url).to eq('mailto:someone@somewebsite.com')
      end
    end
  end
end
