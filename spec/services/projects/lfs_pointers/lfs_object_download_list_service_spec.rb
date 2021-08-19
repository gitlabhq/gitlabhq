# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Projects::LfsPointers::LfsObjectDownloadListService do
  let(:import_url) { 'http://www.gitlab.com/demo/repo.git' }
  let(:default_endpoint) { "#{import_url}/info/lfs/objects/batch"}
  let(:group) { create(:group, lfs_enabled: true)}
  let!(:project) { create(:project, namespace: group, import_url: import_url, lfs_enabled: true) }
  let!(:lfs_objects_project) { create_list(:lfs_objects_project, 2, project: project) }
  let!(:existing_lfs_objects) { LfsObject.pluck(:oid, :size).to_h }
  let(:oids) { { 'oid1' => 123, 'oid2' => 125 } }
  let(:oid_download_links) { { 'oid1' => "#{import_url}/gitlab-lfs/objects/oid1", 'oid2' => "#{import_url}/gitlab-lfs/objects/oid2" } }
  let(:all_oids) { existing_lfs_objects.merge(oids) }
  let(:remote_uri) { URI.parse(lfs_endpoint) }

  subject { described_class.new(project) }

  before do
    allow(project.repository).to receive(:lfsconfig_for).and_return(nil)
    allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
    allow_any_instance_of(Projects::LfsPointers::LfsListService).to receive(:execute).and_return(all_oids)
  end

  describe '#execute' do
    context 'when no lfs pointer is linked' do
      before do
        allow_any_instance_of(Projects::LfsPointers::LfsDownloadLinkListService).to receive(:execute).and_return(oid_download_links)
        expect(Projects::LfsPointers::LfsDownloadLinkListService).to receive(:new).with(project, remote_uri: URI.parse(default_endpoint)).and_call_original
      end

      it 'retrieves all lfs pointers in the project repository' do
        expect_any_instance_of(Projects::LfsPointers::LfsListService).to receive(:execute)

        subject.execute
      end

      context 'when no LFS objects exist' do
        before do
          project.lfs_objects.delete_all
        end

        it 'retrieves all LFS objects' do
          expect_any_instance_of(Projects::LfsPointers::LfsDownloadLinkListService).to receive(:execute).with(all_oids)

          subject.execute
        end
      end

      context 'when some LFS objects already exist' do
        it 'retrieves the download links of non-existent objects' do
          expect_any_instance_of(Projects::LfsPointers::LfsDownloadLinkListService).to receive(:execute).with(oids)

          subject.execute
        end
      end
    end

    context 'when lfsconfig file exists' do
      before do
        allow(project.repository).to receive(:lfsconfig_for).and_return("[lfs]\n\turl = #{lfs_endpoint}\n")
      end

      context 'when url points to the same import url host' do
        let(:lfs_endpoint) { "#{import_url}/different_endpoint" }
        let(:service) { double }

        before do
          allow(service).to receive(:execute)
        end

        it 'downloads lfs object using the new endpoint' do
          expect(Projects::LfsPointers::LfsDownloadLinkListService).to receive(:new).with(project, remote_uri: remote_uri).and_return(service)

          subject.execute
        end

        context 'when import url has credentials' do
          let(:import_url) { 'http://user:password@www.gitlab.com/demo/repo.git'}

          it 'adds the credentials to the new endpoint' do
            expect(Projects::LfsPointers::LfsDownloadLinkListService)
              .to receive(:new).with(project, remote_uri: URI.parse("http://user:password@www.gitlab.com/demo/repo.git/different_endpoint"))
              .and_return(service)

            subject.execute
          end

          context 'when url has its own credentials' do
            let(:lfs_endpoint) { "http://user1:password1@www.gitlab.com/demo/repo.git/different_endpoint" }

            it 'does not add the import url credentials' do
              expect(Projects::LfsPointers::LfsDownloadLinkListService)
                .to receive(:new).with(project, remote_uri: remote_uri)
                .and_return(service)

              subject.execute
            end
          end
        end
      end

      context 'when url points to a third party service' do
        let(:lfs_endpoint) { 'http://third_party_service.com/info/lfs/objects/' }

        it 'disables lfs from the project' do
          expect(project.lfs_enabled?).to be_truthy

          subject.execute

          expect(project.lfs_enabled?).to be_falsey
        end

        it 'does not download anything' do
          expect_any_instance_of(Projects::LfsPointers::LfsListService).not_to receive(:execute)

          subject.execute
        end
      end
    end
  end

  describe '#default_endpoint_uri' do
    let(:import_url) { 'http://www.gitlab.com/demo/repo' }

    it 'adds suffix .git if the url does not have it' do
      expect(subject.send(:default_endpoint_uri).path).to match(/repo.git/)
    end
  end
end
