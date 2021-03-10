# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Maven::Metadata::SyncWorker, type: :worker do
  let_it_be(:versionless_package_for_versions) { create(:maven_package, name: 'MyDummyMavenPkg', version: nil) }
  let_it_be(:metadata_package_file) { create(:package_file, :xml, package: versionless_package_for_versions) }

  let(:versions) { %w[1.2 1.1 2.1 3.0-SNAPSHOT] }
  let(:worker) { described_class.new }

  describe '#perform' do
    let(:user) { create(:user) }
    let(:project) { versionless_package_for_versions.project }
    let(:package_name) { versionless_package_for_versions.name }
    let(:role) { :maintainer }
    let(:most_recent_metadata_file_for_versions) { versionless_package_for_versions.package_files.recent.with_file_name(Packages::Maven::Metadata.filename).first }

    before do
      project.send("add_#{role}", user)
    end

    subject { worker.perform(user.id, project.id, package_name) }

    context 'with a valid package name' do
      before do
        file = CarrierWaveStringFile.new_file(file_content: versions_xml_content, filename: 'maven-metadata.xml', content_type: 'application/xml')
        metadata_package_file.update!(file: file)

        versions.each do |version|
          create(:maven_package, name: versionless_package_for_versions.name, version: version, project: versionless_package_for_versions.project)
        end
      end

      context 'idempotent worker' do
        include_examples 'an idempotent worker' do
          let(:job_args) { [user.id, project.id, package_name] }

          it 'creates the updated metadata files', :aggregate_failures do
            expect { subject }.to change { ::Packages::PackageFile.count }.by(5)

            most_recent_versions = versions_from(most_recent_metadata_file_for_versions.file.read)
            expect(most_recent_versions.latest).to eq('3.0-SNAPSHOT')
            expect(most_recent_versions.release).to eq('2.1')
            expect(most_recent_versions.versions).to match_array(versions)
          end
        end
      end

      it 'logs the message from the service' do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:message, 'New metadata package file created')

        subject
      end

      context 'not in the passed project' do
        let(:project) { create(:project) }

        it 'does not create the updated metadata files' do
          expect { subject }
            .to change { ::Packages::PackageFile.count }.by(0)
            .and raise_error(described_class::SyncError, 'Non existing versionless package')
        end
      end

      context 'with a user with not enough permissions' do
        let(:role) { :guest }

        it 'does not create the updated metadata files' do
          expect { subject }
            .to change { ::Packages::PackageFile.count }.by(0)
            .and raise_error(described_class::SyncError, 'Not allowed')
        end
      end
    end

    context 'with no package name' do
      subject { worker.perform(user.id, project.id, nil) }

      it 'does not run' do
        expect(::Packages::Maven::Metadata::SyncService).not_to receive(:new)
        expect { subject }.not_to change { ::Packages::PackageFile.count }
      end
    end

    context 'with no user id' do
      subject { worker.perform(nil, project.id, package_name) }

      it 'does not run' do
        expect(::Packages::Maven::Metadata::SyncService).not_to receive(:new)
        expect { subject }.not_to change { ::Packages::PackageFile.count }
      end
    end

    context 'with no project id' do
      subject { worker.perform(user.id, nil, package_name) }

      it 'does not run' do
        expect(::Packages::Maven::Metadata::SyncService).not_to receive(:new)
        expect { subject }.not_to change { ::Packages::PackageFile.count }
      end
    end
  end

  def versions_from(xml_content)
    xml_doc = Nokogiri::XML(xml_content)

    OpenStruct.new(
      release: xml_doc.xpath('//metadata/versioning/release').first.content,
      latest: xml_doc.xpath('//metadata/versioning/latest').first.content,
      versions: xml_doc.xpath('//metadata/versioning/versions/version').map(&:content)
    )
  end

  def versions_xml_content
    Nokogiri::XML::Builder.new do |xml|
      xml.metadata do
        xml.groupId(versionless_package_for_versions.maven_metadatum.app_group)
        xml.artifactId(versionless_package_for_versions.maven_metadatum.app_name)
        xml.versioning do
          xml.release('1.3')
          xml.latest('1.3')
          xml.lastUpdated('20210113130531')
          xml.versions do
            xml.version('1.1')
            xml.version('1.2')
            xml.version('1.3')
          end
        end
      end
    end.to_xml
  end
end
