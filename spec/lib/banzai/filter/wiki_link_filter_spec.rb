require 'spec_helper'

describe Banzai::Filter::WikiLinkFilter do
  include FilterSpecHelper

  let(:namespace) { build_stubbed(:namespace, name: "wiki_link_ns") }
  let(:project)   { build_stubbed(:project, :public, name: "wiki_link_project", namespace: namespace) }
  let(:user) { double }
  let(:wiki) { ProjectWiki.new(project, user) }

  it "doesn't rewrite absolute links" do
    filtered_link = filter("<a href='http://example.com:8000/'>Link</a>", project_wiki: wiki).children[0]

    expect(filtered_link.attribute('href').value).to eq('http://example.com:8000/')
  end

  it "doesn't rewrite links to project uploads" do
    filtered_link = filter("<a href='/uploads/a.test'>Link</a>", project_wiki: wiki).children[0]

    expect(filtered_link.attribute('href').value).to eq('/uploads/a.test')
  end

  describe "invalid links" do
    invalid_links = ["http://:8080", "http://", "http://:8080/path"]

    invalid_links.each do |invalid_link|
      it "doesn't rewrite invalid invalid_links like #{invalid_link}" do
        filtered_link = filter("<a href='#{invalid_link}'>Link</a>", project_wiki: wiki).children[0]

        expect(filtered_link.attribute('href').value).to eq(invalid_link)
      end
    end
  end
end
