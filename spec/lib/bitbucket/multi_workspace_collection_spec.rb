# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bitbucket::MultiWorkspaceCollection, feature_category: :importers do
  let(:connection) { instance_double(Bitbucket::Connection) }

  let(:page1) { instance_double(Bitbucket::Page, items: [repo1, repo2], next?: true, next: 'n', attrs: { next: 'n' }) }
  let(:page2) { instance_double(Bitbucket::Page, items: [repo3], next?: false, next: nil, attrs: { next: nil }) }

  let(:repo1) { instance_double(Bitbucket::Representation::Repo, as_json: { 'name' => 'repo1' }) }
  let(:repo2) { instance_double(Bitbucket::Representation::Repo, as_json: { 'name' => 'repo2' }) }
  let(:repo3) { instance_double(Bitbucket::Representation::Repo, as_json: { 'name' => 'repo3' }) }

  let(:workspace_configs) do
    [
      {
        workspace: 'workspace-1',
        path: '/repositories/workspace-1',
        type: :repo,
        page_number: nil,
        has_next_page: nil
      },
      {
        workspace: 'workspace-2',
        path: '/repositories/workspace-2',
        type: :repo,
        page_number: nil,
        has_next_page: nil
      }
    ]
  end

  let(:connection_stub_args) { { 'values' => [repo1.as_json, repo2.as_json], 'next' => nil, 'page' => 1 } }

  subject(:collection) { described_class.new(workspace_configs, connection) }

  before do
    allow(connection).to receive(:get).with(any_args).and_return(connection_stub_args)

    collection.to_a
  end

  describe '#workspace_paging_info' do
    context 'when all workspaces are fully fetched' do
      it 'returns empty array when no workspaces have more pages' do
        expect(collection.workspace_paging_info).to eq([])
      end

      it 'iterates through multiple workspace paginators and returns all items' do
        items = collection.to_a

        expect(items).to all(be_a(Bitbucket::Representation::Repo))

        # 2 workspaces with 2 repos each
        expect(items.length).to eq(4)
      end
    end

    context 'when limit is hit and second workspace is skipped' do
      let(:connection_stub_args) do
        {
          'values' => [repo1.as_json, repo2.as_json],
          'next' => 'https://api.bitbucket.org/2.0/repositories/workspace-1?page=2',
          'page' => 1
        }
      end

      subject(:collection) { described_class.new(workspace_configs, connection, limit: 2) }

      it 'marks fetched workspace with next_page and skipped workspace with next_page: 1' do
        expect(collection.workspace_paging_info).to match_array([
          {
            workspace: 'workspace-1',
            page_info: { has_next_page: true, next_page: 2 }
          },
          {
            workspace: 'workspace-2',
            page_info: { has_next_page: true, next_page: 1 }
          }
        ])
      end
    end

    context 'when resuming from a specific page' do
      let(:connection_stub_args) do
        {
          'values' => [repo1.as_json],
          'next' => 'https://api.bitbucket.org/2.0/repositories/workspace-1?page=3',
          'page' => 2
        }
      end

      let(:workspace_configs_with_page) do
        [
          {
            workspace: 'workspace-1',
            path: '/repositories/workspace-1',
            type: :repo,
            page_number: 2,
            has_next_page: true
          }
        ]
      end

      subject(:collection) { described_class.new(workspace_configs_with_page, connection, limit: 100) }

      it 'extracts next_page from response next URL' do
        expect(collection.workspace_paging_info).to match_array([
          {
            workspace: 'workspace-1',
            page_info: { has_next_page: true, next_page: 3 }
          }
        ])
      end
    end
  end

  describe '#page_info' do
    context 'when no workspaces have been fetched' do
      it 'returns has_next_page: false' do
        collection = described_class.new(workspace_configs, connection)

        expect(collection.page_info).to eq({ has_next_page: false })
      end
    end

    context 'when all workspaces are exhausted' do
      let(:connection_stub_args) { { 'values' => [], 'next' => nil } }

      it 'returns has_next_page: false' do
        expect(collection.page_info).to eq({ has_next_page: false })
      end
    end

    context 'when any workspace has more pages' do
      let(:connection_stub_args) { { 'values' => [repo1.as_json], 'next' => 'next_url', 'page' => 1 } }

      it 'returns has_next_page: true' do
        expect(collection.page_info).to eq({ has_next_page: true })
      end
    end
  end
end
