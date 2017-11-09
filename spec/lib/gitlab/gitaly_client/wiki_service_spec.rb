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
    end
  end
end
