# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GitalyClient::WikiService do
  let(:project) { create(:project) }
  let(:storage_name) { project.repository_storage }
  let(:relative_path) { project.disk_path + '.git' }
  let(:client) { described_class.new(project.repository) }
  let(:commit) { create(:gitaly_commit) }
  let(:page_version) { Gitaly::WikiPageVersion.new(format: 'markdown', commit: commit) }
  let(:page_info) { { title: 'My Page', raw_data: 'a', version: page_version } }

  describe '#find_page' do
    let(:response) do
      [
        Gitaly::WikiFindPageResponse.new(page: Gitaly::WikiPage.new(page_info)),
        Gitaly::WikiFindPageResponse.new(page: Gitaly::WikiPage.new(raw_data: 'b'))
      ]
    end
    let(:wiki_page) { subject.first }
    let(:wiki_page_version) { subject.last }

    subject { client.find_page(title: 'My Page', version: 'master', dir: '') }

    it 'sends a wiki_find_page message' do
      expect_any_instance_of(Gitaly::WikiService::Stub)
        .to receive(:wiki_find_page)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return([].each)

      subject
    end

    it 'concatenates the raw data and returns a pair of WikiPage and WikiPageVersion' do
      expect_any_instance_of(Gitaly::WikiService::Stub)
        .to receive(:wiki_find_page)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(response.each)

      expect(wiki_page.title).to eq('My Page')
      expect(wiki_page.raw_data).to eq('ab')
      expect(wiki_page_version.format).to eq('markdown')

      expect(wiki_page.title).to be_utf8
      expect(wiki_page.path).to be_utf8
      expect(wiki_page.name).to be_utf8
    end
  end

  describe '#load_all_pages' do
    let(:page_2_info) { { title: 'My Page 2', raw_data: 'c', version: page_version } }
    let(:response) do
      [
        Gitaly::WikiGetAllPagesResponse.new(page: Gitaly::WikiPage.new(page_info)),
        Gitaly::WikiGetAllPagesResponse.new(page: Gitaly::WikiPage.new(raw_data: 'b')),
        Gitaly::WikiGetAllPagesResponse.new(end_of_page: true),
        Gitaly::WikiGetAllPagesResponse.new(page: Gitaly::WikiPage.new(page_2_info)),
        Gitaly::WikiGetAllPagesResponse.new(page: Gitaly::WikiPage.new(raw_data: 'd')),
        Gitaly::WikiGetAllPagesResponse.new(end_of_page: true)
      ]
    end
    let(:wiki_page_1) { subject[0].first }
    let(:wiki_page_1_version) { subject[0].last }
    let(:wiki_page_2) { subject[1].first }
    let(:wiki_page_2_version) { subject[1].last }

    subject { client.load_all_pages }

    it 'sends a wiki_get_all_pages message' do
      expect_any_instance_of(Gitaly::WikiService::Stub)
        .to receive(:wiki_get_all_pages)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return([].each)

      subject
    end

    it 'sends a limit of 0 to wiki_get_all_pages' do
      expect_any_instance_of(Gitaly::WikiService::Stub)
        .to receive(:wiki_get_all_pages)
        .with(gitaly_request_with_params(limit: 0), kind_of(Hash))
        .and_return([].each)

      subject
    end

    it 'concatenates the raw data and returns a pair of WikiPage and WikiPageVersion for each page' do
      expect_any_instance_of(Gitaly::WikiService::Stub)
        .to receive(:wiki_get_all_pages)
        .with(gitaly_request_with_path(storage_name, relative_path), kind_of(Hash))
        .and_return(response.each)

      expect(subject.size).to be(2)
      expect(wiki_page_1.title).to eq('My Page')
      expect(wiki_page_1.raw_data).to eq('ab')
      expect(wiki_page_1_version.format).to eq('markdown')
      expect(wiki_page_2.title).to eq('My Page 2')
      expect(wiki_page_2.raw_data).to eq('cd')
      expect(wiki_page_2_version.format).to eq('markdown')
    end

    context 'with limits' do
      subject { client.load_all_pages(limit: 1) }

      it 'sends a request with the limit' do
        expect_any_instance_of(Gitaly::WikiService::Stub)
        .to receive(:wiki_get_all_pages)
        .with(gitaly_request_with_params(limit: 1), kind_of(Hash))
        .and_return([].each)

        subject
      end
    end
  end
end
