# frozen_string_literal: true

require 'spec_helper'
require './keeps/update_zoekt_compatibility_matrix'

RSpec.describe Keeps::UpdateZoektCompatibilityMatrix, feature_category: :global_search do
  subject(:keep) { described_class.new }

  let(:api_url) { described_class::API_URL }
  let(:tmp_dir) { Pathname(Dir.mktmpdir) }
  let(:doc_path) { tmp_dir.join('_index.md').to_s }
  let(:groups_helper) { instance_double(Keeps::Helpers::Groups, group_for_group_label: {}, pick_reviewer: 'reviewer') }

  let(:current_table) do
    <<~MARKDOWN
      | GitLab version | `gitlab-zoekt-indexer` version | `gitlab-zoekt` chart version |
      |----------------|--------------------------------|------------------------------|
      | 18.6           | 1.7.6                          | 3.7.1                        |
    MARKDOWN
  end

  let(:expected_table) do
    <<~MARKDOWN
      | GitLab version | `gitlab-zoekt-indexer` version | `gitlab-zoekt` chart version |
      |----------------|--------------------------------|------------------------------|
      | 18.8           | 1.8.0                          | 3.8.0                        |
      | 18.6 and 18.7  | 1.7.6                          | 3.7.1                        |
    MARKDOWN
  end

  let(:doc) do
    <<~MARKDOWN
      # Zoekt

      ## Version compatibility

      Each GitLab version comes with a specific `gitlab-zoekt-indexer` and `gitlab-zoekt` chart version.

      #{current_table}
      ## Install Zoekt

      | Other | Table |
      |-------|-------|
    MARKDOWN
  end

  before do
    stub_const("#{described_class}::DOC_PATH", doc_path)
    File.write(doc_path, doc)

    allow(Keeps::Helpers::Groups).to receive(:instance).and_return(groups_helper)

    stub_release(18, 6, indexer: 'v1.7.6', chart: '3.7.1', chart_indexer: 'v1.7.6')
    stub_release(18, 7, indexer: '1.7.6', chart: '3.7.1', chart_indexer: 'v1.7.6')
    stub_release(18, 8, indexer: '1.8.0', chart: '3.8.0', chart_indexer: 'v1.7.6-abc123')
    stub_request(:get, "#{api_url}/projects/gitlab-org%2Fgitlab/repository/tags/v18.9.0-ee").to_return(status: 404)
  end

  after do
    FileUtils.rm_rf(tmp_dir)
  end

  def stub_release(major, minor, indexer:, chart:, chart_indexer:)
    stub_request(:get, "#{api_url}/projects/gitlab-org%2Fgitlab/repository/tags/v#{major}.#{minor}.0-ee")
      .to_return(status: 200, body: '{}')
    stub_raw_file('gitlab-org%2Fgitlab', 'GITLAB_ZOEKT_VERSION', "#{major}-#{minor}-stable-ee", "#{indexer}\n")
    stub_raw_file('gitlab-org%2Fcharts%2Fgitlab', 'Chart.yaml', "#{major - 9}-#{minor}-stable", <<~YAML)
      dependencies:
      - name: gitlab
        version: "*.*.*"
      - name: gitlab-zoekt
        version: #{chart}
    YAML
    stub_raw_file('gitlab-org%2Fcloud-native%2Fcharts%2Fgitlab-zoekt', 'values.yaml', "v#{chart}", <<~YAML)
      indexer:
        image:
          tag: #{chart_indexer}
      gateway:
        image:
          tag: 1.25.5
    YAML
  end

  def stub_raw_file(project, path, ref, body)
    stub_request(:get, "#{api_url}/projects/#{project}/repository/files/#{path}/raw?ref=#{ref}")
      .to_return(status: 200, body: body)
  end

  def identified_changes
    changes = []
    keep.each_identified_change { |change| changes << change }
    changes
  end

  describe '#each_identified_change' do
    it 'yields one change with a stable identifier' do
      changes = identified_changes

      expect(changes.size).to eq(1)
      expect(changes.first.identifiers).to eq(['UpdateZoektCompatibilityMatrix'])
      expect(changes.first.context[:table]).to eq(expected_table.chomp)
    end

    context 'when the published table is up to date' do
      let(:current_table) { expected_table }

      it 'yields no change' do
        expect { |b| keep.each_identified_change(&b) }.not_to yield_control
      end
    end

    context 'when no GitLab version is released' do
      before do
        stub_request(:get, "#{api_url}/projects/gitlab-org%2Fgitlab/repository/tags/v18.6.0-ee").to_return(status: 404)
      end

      it 'raises an error' do
        expect { identified_changes }.to raise_error(described_class::Error, 'No released GitLab versions found')
      end
    end

    context 'when an API request fails' do
      before do
        stub_request(:get, "#{api_url}/projects/gitlab-org%2Fcharts%2Fgitlab/repository/files/Chart.yaml/raw")
          .with(query: { ref: '9-7-stable' })
          .to_return(status: 500)
      end

      it 'raises an error' do
        expect { identified_changes }.to raise_error(described_class::Error, /failed with response code 500/)
      end
    end

    context 'when versions cross a major release' do
      let(:expected_table) do
        <<~MARKDOWN
          | GitLab version | `gitlab-zoekt-indexer` version | `gitlab-zoekt` chart version |
          |----------------|--------------------------------|------------------------------|
          | 18.11 to 19.1  | 1.13.1                         | 3.11.0                       |
        MARKDOWN
      end

      before do
        stub_const("#{described_class}::FIRST_VERSION", [18, 11])

        stub_release(18, 11, indexer: '1.13.1', chart: '3.11.0', chart_indexer: 'v1.13.1')
        stub_release(19, 0, indexer: '1.13.1', chart: '3.11.0', chart_indexer: 'v1.13.1')
        stub_release(19, 1, indexer: '1.13.1', chart: '3.11.0', chart_indexer: 'v1.13.1')
        stub_request(:get, "#{api_url}/projects/gitlab-org%2Fgitlab/repository/tags/v19.2.0-ee").to_return(status: 404)
      end

      it 'rolls over to the next major version and collapses the range' do
        expect(identified_changes.first.context[:table]).to eq(expected_table.chomp)
      end
    end

    context 'when a chart has no gitlab-zoekt dependency' do
      before do
        stub_raw_file('gitlab-org%2Fcharts%2Fgitlab', 'Chart.yaml', '9-7-stable', <<~YAML)
          dependencies:
          - name: gitlab
            version: "*.*.*"
        YAML
      end

      it 'raises an error' do
        expect { identified_changes }.to raise_error(described_class::Error,
          'No gitlab-zoekt chart dependency for GitLab 18.7')
      end
    end

    context 'when a chart has no dependencies' do
      before do
        stub_raw_file('gitlab-org%2Fcharts%2Fgitlab', 'Chart.yaml', '9-7-stable', "name: gitlab\n")
      end

      it 'raises an error' do
        expect { identified_changes }.to raise_error(described_class::Error,
          'No gitlab-zoekt chart dependency for GitLab 18.7')
      end
    end

    context 'when a chart version is not a string' do
      before do
        stub_raw_file('gitlab-org%2Fcharts%2Fgitlab', 'Chart.yaml', '9-7-stable', <<~YAML)
          dependencies:
          - name: gitlab-zoekt
            version: 3.10
        YAML
      end

      it 'raises an error' do
        expect { identified_changes }.to raise_error(described_class::Error,
          'gitlab-zoekt chart version for GitLab 18.7 is missing or is not a string')
      end
    end

    context 'when a chart has no indexer image tag' do
      before do
        stub_raw_file('gitlab-org%2Fcloud-native%2Fcharts%2Fgitlab-zoekt', 'values.yaml', 'v3.8.0', "indexer: {}\n")
      end

      it 'raises an error' do
        expect { identified_changes }.to raise_error(described_class::Error,
          'indexer.image.tag in gitlab-zoekt chart 3.8.0 is missing or is not a string')
      end
    end

    context 'when Chart.yaml is empty' do
      before do
        stub_raw_file('gitlab-org%2Fcharts%2Fgitlab', 'Chart.yaml', '9-7-stable', '')
      end

      it 'raises an error instead of a NoMethodError' do
        expect { identified_changes }.to raise_error(described_class::Error,
          'Chart.yaml on 9-7-stable is empty or not a YAML mapping')
      end
    end

    context 'when values.yaml is empty' do
      before do
        stub_raw_file('gitlab-org%2Fcloud-native%2Fcharts%2Fgitlab-zoekt', 'values.yaml', 'v3.8.0', '')
      end

      it 'raises an error instead of a NoMethodError' do
        expect { identified_changes }.to raise_error(described_class::Error,
          'values.yaml in gitlab-zoekt chart 3.8.0 is empty or not a YAML mapping')
      end
    end

    context 'when the section heading is missing' do
      let(:doc) { "# Zoekt\n" }

      it 'raises an error' do
        expect { identified_changes }.to raise_error(described_class::Error, /## Version compatibility not found/)
      end
    end
  end

  describe '#recreate_when_closed?' do
    it 'recreates the MR after a closed one' do
      expect(keep.recreate_when_closed?).to be(true)
    end
  end

  describe '#make_change!' do
    subject(:change) { keep.make_change!(identified_changes.first) }

    it 'replaces only the compatibility table' do
      change

      expect(File.read(doc_path)).to eq(doc.sub(current_table, expected_table))
    end

    it 'sets the change attributes' do
      expect(change.title).to eq('Update Zoekt version compatibility table')
      expect(change.changed_files).to eq([doc_path])
      expect(change.labels).to include('documentation', 'group::global search')
      expect(change.assignees).to eq(['reviewer'])
    end

    it 'seeds the assignee with the latest GitLab version' do
      change

      expect(groups_helper).to have_received(:pick_reviewer).with({}, ['UpdateZoektCompatibilityMatrix', '18.8'])
    end

    it 'warns about releases whose chart deploys a different indexer version' do
      expect(change.description).to include('## Chart and indexer versions differ')
      expect(change.description).to include(
        '- GitLab 18.8: `GITLAB_ZOEKT_VERSION` is 1.8.0, but `gitlab-zoekt` chart 3.8.0 deploys indexer 1.7.6.'
      )
      expect(change.description).not_to include('GitLab 18.6:')
    end

    context 'when no reviewer is available' do
      let(:groups_helper) { instance_double(Keeps::Helpers::Groups, group_for_group_label: {}, pick_reviewer: nil) }

      it 'leaves the change unassigned' do
        expect(change.assignees).to be_empty
      end
    end

    context 'when the section has no table' do
      let(:current_table) { '' }

      it 'raises an error' do
        expect { change }.to raise_error(described_class::Error, /No table found under ## Version compatibility/)
      end
    end

    context 'when every chart deploys the tested indexer version' do
      before do
        stub_release(18, 8, indexer: '1.8.0', chart: '3.8.0', chart_indexer: 'v1.8.0')
      end

      it 'does not warn' do
        expect(change.description).not_to include('Chart and indexer versions differ')
      end
    end
  end
end
