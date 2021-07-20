# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::WikiLinkFilter do
  include FilterSpecHelper

  let(:namespace) { build_stubbed(:namespace, name: "wiki_link_ns") }
  let(:project)   { build_stubbed(:project, :public, name: "wiki_link_project", namespace: namespace) }
  let(:wiki) { ProjectWiki.new(project, nil) }
  let(:repository_upload_folder) { Wikis::CreateAttachmentService::ATTACHMENT_PATH }

  it "doesn't rewrite absolute links" do
    filtered_link = filter("<a href='http://example.com:8000/'>Link</a>", wiki: wiki).children[0]

    expect(filtered_link.attribute('href').value).to eq('http://example.com:8000/')
  end

  it "doesn't rewrite links to project uploads" do
    filtered_link = filter("<a href='/uploads/a.test'>Link</a>", wiki: wiki).children[0]

    expect(filtered_link.attribute('href').value).to eq('/uploads/a.test')
  end

  describe 'when links are rewritable' do
    it "stores original url in the data-canonical-src attribute" do
      original_path = "#{repository_upload_folder}/a.jpg"
      filtered_elements = filter("<a href='#{original_path}'><img src='#{original_path}'>example</img></a>", wiki: wiki)

      expect(filtered_elements.search('img').first.attribute('data-canonical-src').value).to eq(original_path)
      expect(filtered_elements.search('a').first.attribute('data-canonical-src').value).to eq(original_path)
    end
  end

  describe 'when links are not rewritable' do
    it "does not store original url in the data-canonical-src attribute" do
      filtered_link = filter("<a href='/uploads/a.test'>Link</a>", wiki: wiki).children[0]

      expect(filtered_link.value?('data-canonical-src')).to eq(false)
    end
  end

  describe 'when links point to the relative wiki path' do
    it 'does not rewrite links' do
      path = "#{wiki.wiki_base_path}/#{repository_upload_folder}/a.jpg"
      filtered_link = filter("<a href='#{path}'>Link</a>", wiki: wiki, page_slug: 'home').children[0]

      expect(filtered_link.attribute('href').value).to eq(path)
    end
  end

  describe "when links point to the #{Wikis::CreateAttachmentService::ATTACHMENT_PATH} folder" do
    context 'with an "a" html tag' do
      it 'rewrites links' do
        filtered_link = filter("<a href='#{repository_upload_folder}/a.test'>Link</a>", wiki: wiki).children[0]

        expect(filtered_link.attribute('href').value).to eq("#{wiki.wiki_base_path}/#{repository_upload_folder}/a.test")
      end
    end

    context 'with "img" html tag' do
      let(:path) { "#{wiki.wiki_base_path}/#{repository_upload_folder}/a.jpg" }

      context 'inside an "a" html tag' do
        it 'rewrites links' do
          filtered_elements = filter("<a href='#{repository_upload_folder}/a.jpg'><img src='#{repository_upload_folder}/a.jpg'>example</img></a>", wiki: wiki)

          expect(filtered_elements.search('img').first.attribute('src').value).to eq(path)
          expect(filtered_elements.search('a').first.attribute('href').value).to eq(path)
        end
      end

      context 'outside an "a" html tag' do
        it 'rewrites links' do
          filtered_link = filter("<img src='#{repository_upload_folder}/a.jpg'>example</img>", wiki: wiki).children[0]

          expect(filtered_link.attribute('src').value).to eq(path)
        end
      end
    end

    context 'with "video" html tag' do
      it 'rewrites links' do
        filtered_link = filter("<video src='#{repository_upload_folder}/a.mp4'></video>", wiki: wiki).children[0]

        expect(filtered_link.attribute('src').value).to eq("#{wiki.wiki_base_path}/#{repository_upload_folder}/a.mp4")
      end
    end

    context 'with "audio" html tag' do
      it 'rewrites links' do
        filtered_link = filter("<audio src='#{repository_upload_folder}/a.wav'></audio>", wiki: wiki).children[0]

        expect(filtered_link.attribute('src').value).to eq("#{wiki.wiki_base_path}/#{repository_upload_folder}/a.wav")
      end
    end
  end

  describe "invalid links" do
    invalid_links = ["http://:8080", "http://", "http://:8080/path"]

    invalid_links.each do |invalid_link|
      it "doesn't rewrite invalid invalid_links like #{invalid_link}" do
        filtered_link = filter("<a href='#{invalid_link}'>Link</a>", wiki: wiki).children[0]

        expect(filtered_link.attribute('href').value).to eq(invalid_link)
      end
    end
  end
end
