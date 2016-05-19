require 'spec_helper'

describe Banzai::Filter::WikiLinkFilter, lib: true do
  include FilterSpecHelper

  let(:namespace) { build_stubbed(:namespace, name: "wiki_link_ns") }
  let(:project)   { build_stubbed(:empty_project, :public, name: "wiki_link_project", namespace: namespace) }
  let(:user) { double }
  let(:project_wiki) { ProjectWiki.new(project, user) }

  describe "links within the wiki (relative)" do
    describe "hierarchical links to the current directory" do
      it "doesn't rewrite non-file links" do
        link = "<a href='./page'>Link to Page</a>"
        filtered_link = filter(link, project_wiki: project_wiki).children[0]

        expect(filtered_link.attribute('href').value).to eq('./page')
      end

      it "doesn't rewrite file links" do
        link = "<a href='./page.md'>Link to Page</a>"
        filtered_link = filter(link, project_wiki: project_wiki).children[0]

        expect(filtered_link.attribute('href').value).to eq('./page.md')
      end
    end

    describe "hierarchical links to the parent directory" do
      it "doesn't rewrite non-file links" do
        link = "<a href='../page'>Link to Page</a>"
        filtered_link = filter(link, project_wiki: project_wiki).children[0]

        expect(filtered_link.attribute('href').value).to eq('../page')
      end

      it "doesn't rewrite file links" do
        link = "<a href='../page.md'>Link to Page</a>"
        filtered_link = filter(link, project_wiki: project_wiki).children[0]

        expect(filtered_link.attribute('href').value).to eq('../page.md')
      end
    end

    describe "hierarchical links to a sub-directory" do
      it "doesn't rewrite non-file links" do
        link = "<a href='./subdirectory/page'>Link to Page</a>"
        filtered_link = filter(link, project_wiki: project_wiki).children[0]

        expect(filtered_link.attribute('href').value).to eq('./subdirectory/page')
      end

      it "doesn't rewrite file links" do
        link = "<a href='./subdirectory/page.md'>Link to Page</a>"
        filtered_link = filter(link, project_wiki: project_wiki).children[0]

        expect(filtered_link.attribute('href').value).to eq('./subdirectory/page.md')
      end
    end

    describe "non-hierarchical links" do
      it 'rewrites non-file links to be at the scope of the wiki root' do
        link = "<a href='page'>Link to Page</a>"
        filtered_link = filter(link, project_wiki: project_wiki).children[0]

        expect(filtered_link.attribute('href').value).to match('/wiki_link_ns/wiki_link_project/wikis/page')
      end

      it "doesn't rewrite file links" do
        link = "<a href='page.md'>Link to Page</a>"
        filtered_link = filter(link, project_wiki: project_wiki).children[0]

        expect(filtered_link.attribute('href').value).to eq('page.md')
      end
    end
  end

  describe "links outside the wiki (absolute)" do
    it "doesn't rewrite links" do
      link = "<a href='http://example.com/page'>Link to Page</a>"
      filtered_link = filter(link, project_wiki: project_wiki).children[0]

      expect(filtered_link.attribute('href').value).to eq('http://example.com/page')
    end
  end
end
