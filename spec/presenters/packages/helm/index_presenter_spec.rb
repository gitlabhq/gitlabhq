# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Helm::IndexPresenter do
  include_context 'with expected presenters dependency groups'

  let_it_be(:project) { create(:project) }
  let_it_be(:packages) { create_list(:helm_package, 5, project: project) }
  let_it_be(:package_files3_1) { create(:helm_package_file, package: packages[2], file_sha256: '3_1', file_name: 'file3_1') }
  let_it_be(:package_files3_2) { create(:helm_package_file, package: packages[2], file_sha256: '3_2', file_name: 'file3_2') }
  let_it_be(:package_files4_1) { create(:helm_package_file, package: packages[3], file_sha256: '4_1', file_name: 'file4_1') }
  let_it_be(:package_files4_2) { create(:helm_package_file, package: packages[3], file_sha256: '4_2', file_name: 'file4_2') }
  let_it_be(:package_files4_3) { create(:helm_package_file, package: packages[3], file_sha256: '4_3', file_name: 'file4_3') }

  let(:project_id_param) { project.id }
  let(:channel) { 'stable' }
  let(:presenter) { described_class.new(project_id_param, channel, ::Packages::Package.id_in(packages.map(&:id))) }

  describe('#entries') do
    subject { presenter.entries }

    it 'returns the correct hash' do
      expect(subject.size).to eq(5)
      expect(subject.keys).to eq(packages.map(&:name))
      subject.values.zip(packages) do |raws, pkg|
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

    context 'with an unknown channel' do
      let(:channel) { 'unknown' }

      it { is_expected.to be_empty }
    end

    context 'with a nil channel' do
      let(:channel) { nil }

      it { is_expected.to be_empty }
    end
  end

  describe('#api_version') do
    subject { presenter.api_version }

    it { is_expected.to eq(described_class::API_VERSION) }
  end

  describe('#generated') do
    subject { presenter.generated }

    it 'returns the expected format' do
      freeze_time do
        expect(subject).to eq(Time.zone.now.utc.strftime('%Y-%m-%dT%H:%M:%S.%NZ'))
      end
    end
  end

  describe('#server_info') do
    subject { presenter.server_info }

    it { is_expected.to eq({ 'contextPath' => "/api/v4/projects/#{project.id}/packages/helm" }) }

    context 'with url encoded project id param' do
      let_it_be(:project_id_param) { 'foo/bar' }

      it { is_expected.to eq({ 'contextPath' => '/api/v4/projects/foo%2Fbar/packages/helm' }) }
    end
  end
end
