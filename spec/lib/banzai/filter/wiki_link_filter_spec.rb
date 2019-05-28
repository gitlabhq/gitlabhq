require 'spec_helper'

describe Banzai::Filter::WikiLinkFilter do
  include FilterSpecHelper

  let(:namespace) { build_stubbed(:namespace, name: "wiki_link_ns") }
  let(:project)   { build_stubbed(:project, :public, name: "wiki_link_project", namespace: namespace) }
  let(:user) { double }
  let(:wiki) { ProjectWiki.new(project, user) }
  let(:repository_upload_folder) { Wikis::CreateAttachmentService::ATTACHMENT_PATH }

  it "doesn't rewrite absolute links" do
    filtered_link = filter("<a href='http://example.com:8000/'>Link</a>", project_wiki: wiki).children[0]

    expect(filtered_link.attribute('href').value).to eq('http://example.com:8000/')
  end

  it "doesn't rewrite links to project uploads" do
    filtered_link = filter("<a href='/uploads/a.test'>Link</a>", project_wiki: wiki).children[0]

    expect(filtered_link.attribute('href').value).to eq('/uploads/a.test')
  end

  describe "when links point to the #{Wikis::CreateAttachmentService::ATTACHMENT_PATH} folder" do
    context 'with an "a" html tag' do
      it 'rewrites links' do
        filtered_link = filter("<a href='#{repository_upload_folder}/a.test'>Link</a>", project_wiki: wiki).children[0]

        expect(filtered_link.attribute('href').value).to eq("#{wiki.wiki_base_path}/#{repository_upload_folder}/a.test")
      end
    end

    context 'with "img" html tag' do
      let(:path) { "#{wiki.wiki_base_path}/#{repository_upload_folder}/a.jpg" }

      context 'inside an "a" html tag' do
        it 'rewrites links' do
          filtered_elements = filter("<a href='#{repository_upload_folder}/a.jpg'><img src='#{repository_upload_folder}/a.jpg'>example</img></a>", project_wiki: wiki)

          expect(filtered_elements.search('img').first.attribute('src').value).to eq(path)
          expect(filtered_elements.search('a').first.attribute('href').value).to eq(path)
        end
      end

      context 'outside an "a" html tag' do
        it 'rewrites links' do
          filtered_link = filter("<img src='#{repository_upload_folder}/a.jpg'>example</img>", project_wiki: wiki).children[0]

          expect(filtered_link.attribute('src').value).to eq(path)
        end
      end
    end

    context 'with "video" html tag' do
      it 'rewrites links' do
        filtered_link = filter("<video src='#{repository_upload_folder}/a.mp4'></video>", project_wiki: wiki).children[0]

        expect(filtered_link.attribute('src').value).to eq("#{wiki.wiki_base_path}/#{repository_upload_folder}/a.mp4")
      end
    end
  end

  describe "invalid links" do
    invalid_links = ["http://:8080", "http://", "http://:8080/path"]

    invalid_links.each do |invalid_link|
      it "doesn't rewrite invalid invalid_links like #{invalid_link}" do
        filtered_link = filter("<a href='#{invalid_link}'>Link</a>", project_wiki: wiki).children[0]

        expect(filtered_link.attribute('href').value).to eq(invalid_link)
      end
    end

    context "when the slug is deemed unsafe or invalid" do
      let(:link) { "alert(1);" }

      invalid_slugs = [
        "javascript:",
        "JaVaScRiPt:",
        "\u0001java\u0003script:",
        "javascript    :",
        "javascript:    ",
        "javascript    :   ",
        ":javascript:",
        "javascript&#58;",
        "javascript&#0058;",
        "javascript&#x3A;",
        "javascript&#x003A;",
        "java\0script:",
        " &#14;  javascript:"
        ]

      invalid_slugs.each do |slug|
        context "with the slug #{slug}" do
          it "doesn't rewrite a (.) relative link" do
            filtered_link = filter(
              "<a href='.#{link}'>Link</a>",
              project_wiki: wiki,
              page_slug: slug).children[0]

            expect(filtered_link.attribute('href').value).not_to include(slug)
          end

          it "doesn't rewrite a (..) relative link" do
            filtered_link = filter(
              "<a href='..#{link}'>Link</a>",
              project_wiki: wiki,
              page_slug: slug).children[0]

            expect(filtered_link.attribute('href').value).not_to include(slug)
          end
        end
      end
    end
  end
end
