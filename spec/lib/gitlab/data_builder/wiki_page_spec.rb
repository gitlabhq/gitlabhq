require 'spec_helper'

describe Gitlab::DataBuilder::WikiPage do
  let(:project) { create(:project, :repository) }
  let(:wiki_page) { create(:wiki_page, wiki: project.wiki) }
  let(:user) { create(:user) }

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
  end
end
