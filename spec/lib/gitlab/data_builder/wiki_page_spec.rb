# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DataBuilder::WikiPage, feature_category: :wiki do
  let_it_be(:project) { create(:project, :repository, :wiki_repo) }
  let_it_be(:wiki_page) { create(:wiki_page, wiki: project.wiki) }
  let_it_be(:user) { create(:user) }

  describe '.build' do
    let(:data) { described_class.build(wiki_page, user, 'create') }

    it { expect(data).to be_a(Hash) }
    it { expect(data[:object_kind]).to eq('wiki_page') }
    it { expect(data[:user]).to eq(user.hook_attrs) }
    it { expect(data[:project]).to eq(project.hook_attrs) }
    it { expect(data[:wiki]).to eq(project.wiki.hook_attrs) }

    it { expect(data[:object_attributes]).to include(wiki_page.hook_attrs) }
    it { expect(data[:object_attributes]).to include(url: Gitlab::UrlBuilder.build(wiki_page)) }
    it { expect(data[:object_attributes]).to include(action: 'create') }
    it { expect(data[:object_attributes]).to include(diff_url: Gitlab::UrlBuilder.build(wiki_page, action: :diff, version_id: wiki_page.version.id)) }
  end
end
