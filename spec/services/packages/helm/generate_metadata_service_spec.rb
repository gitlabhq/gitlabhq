# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Helm::GenerateMetadataService, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:packages) { create_list(:helm_package, 5, project: project) }
  let_it_be(:package_files3_1) do
    create(:helm_package_file, package: packages[2], file_sha256: '3_1', file_name: 'file3_1')
  end

  let_it_be(:package_files3_2) do
    create(:helm_package_file, package: packages[2], file_sha256: '3_2', file_name: 'file3_2')
  end

  let_it_be(:package_files4_1) do
    create(:helm_package_file, package: packages[3], file_sha256: '4_1', file_name: 'file4_1')
  end

  let_it_be(:package_files4_2) do
    create(:helm_package_file, package: packages[3], file_sha256: '4_2', file_name: 'file4_2')
  end

  let_it_be(:package_files4_3) do
    create(:helm_package_file, package: packages[3], file_sha256: '4_3', file_name: 'file4_3')
  end

  let(:project_id_param) { project.id }
  let(:channel) { 'stable' }

  describe '#execute' do
    subject(:response) do
      described_class.new(project_id_param, channel, ::Packages::Package.id_in(packages.map(&:id))).execute
    end

    shared_examples 'empty entries' do
      it "returns empty entries in the payload" do
        expect(response.payload[:entries]).to be_empty
      end
    end

    it 'returns entries in the payload' do
      entries = response.payload[:entries]

      expect(entries.size).to eq(5)
      expect(entries.keys).to eq(packages.map(&:name))
      entries.values.zip(packages) do |raws, pkg|
        expect(raws.size).to eq(1)

        file = pkg.package_files.recent.first
        raw = raws.first
        expect(raw['name']).to eq(pkg.name)
        expect(raw['version']).to eq(pkg.version)
        expect(raw['apiVersion']).to eq("v2")
        expect(raw['created']).to eq(file.created_at.utc.strftime('%Y-%m-%dT%H:%M:%S.%NZ'))
        expect(raw['digest']).to eq(file.file_sha256)
        expect(raw['urls']).to eq(["charts/#{file.file_name}"])
      end
    end

    it 'returns api_version in the payload' do
      expect(response.payload[:api_version]).to eq(described_class::API_VERSION)
    end

    it 'returns generated timestamp in the payload' do
      freeze_time do
        expect(response.payload[:generated]).to eq(Time.zone.now.utc.strftime('%Y-%m-%dT%H:%M:%S.%NZ'))
      end
    end

    it 'returns server_info in the payload' do
      expect(response.payload[:server_info]).to eq(
        { 'contextPath' => "/api/v4/projects/#{project.id}/packages/helm" }
      )
    end

    context 'when channel is unknown' do
      let(:channel) { 'unknown' }

      it_behaves_like 'empty entries'
    end

    context 'when channel is nil' do
      let(:channel) { nil }

      it_behaves_like 'empty entries'
    end

    context 'when project_id_param is not integer' do
      let_it_be(:project_id_param) { 'foo/bar' }

      it 'returns encoded project_id_params in contextPath' do
        expect(response.payload[:server_info]).to eq(
          { 'contextPath' => '/api/v4/projects/foo%2Fbar/packages/helm' }
        )
      end
    end
  end
end
