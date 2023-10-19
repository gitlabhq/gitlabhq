# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::OdataPackageEntryService, feature_category: :package_registry do
  include GrapePathHelpers::NamedRouteMatcher

  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:params) { { package_name: 'dummy', package_version: '1.0.0' } }
  let(:doc) { Nokogiri::XML(subject.payload) }

  subject { described_class.new(project, params).execute }

  describe '#execute' do
    shared_examples 'returning a package entry with the correct attributes' do |pkg_version = ''|
      it 'returns a package entry with the correct attributes' do
        expect(doc.root.name).to eq('entry')
        expect(doc_node('id').text).to include(
          id_url(project.id, params[:package_name], pkg_version)
        )
        expect(doc_node('title').text).to eq(params[:package_name])
        expect(doc_node('content').attr('src')).to include(
          content_url(project.id, params[:package_name], pkg_version)
        )
        expect(doc_node('Version').text).to eq(pkg_version)
      end
    end

    context 'when package_version is present' do
      it 'returns a success ServiceResponse' do
        expect(subject).to be_success
      end

      it_behaves_like 'returning a package entry with the correct attributes', '1.0.0'
    end

    context 'when package_version is not present' do
      let(:params) { { package_name: 'dummy', package_version: nil } }

      it 'returns a success ServiceResponse' do
        expect(subject).to be_success
      end

      it_behaves_like 'returning a package entry with the correct attributes'
    end
  end

  def doc_node(name)
    doc.css('*').detect { |el| el.name == name }
  end

  def id_url(id, package_name, package_version)
    "api/v4/projects/#{id}/packages/nuget/v2/Packages(Id='#{package_name}',Version='#{package_version}')"
  end

  def content_url(id, package_name, package_version)
    if package_version.present?
      filename = "#{package_name}.#{package_version}.nupkg"
      api_v4_projects_packages_nuget_download_package_name_package_version_package_filename_path(
        { id: id, package_name: package_name, package_version: package_version, package_filename: filename }, true
      )
    else
      api_v4_projects_packages_nuget_v2_path(id: id)
    end
  end
end
