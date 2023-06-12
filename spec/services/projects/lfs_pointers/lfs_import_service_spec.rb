# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Projects::LfsPointers::LfsImportService, feature_category: :source_code_management do
  let(:project) { create(:project) }
  let(:user) { project.creator }
  let(:import_url) { 'http://www.gitlab.com/demo/repo.git' }
  let(:oid_download_links) do
    [
      { 'oid1' => "#{import_url}/gitlab-lfs/objects/oid1" },
      { 'oid2' => "#{import_url}/gitlab-lfs/objects/oid2" }
    ]
  end

  subject { described_class.new(project, user) }

  context 'when lfs is enabled for the project' do
    before do
      allow(project).to receive(:lfs_enabled?).and_return(true)
    end

    it 'downloads lfs objects' do
      service = double
      expect_next_instance_of(Projects::LfsPointers::LfsObjectDownloadListService) do |instance|
        expect(instance).to receive(:each_list_item)
          .and_yield(oid_download_links[0]).and_yield(oid_download_links[1])
      end
      expect(Projects::LfsPointers::LfsDownloadService).to receive(:new).and_return(service).twice
      expect(service).to receive(:execute).twice

      result = subject.execute

      expect(result[:status]).to eq :success
    end

    context 'when no downloadable lfs object links' do
      it 'does not call LfsDownloadService' do
        expect_next_instance_of(Projects::LfsPointers::LfsObjectDownloadListService) do |instance|
          expect(instance).to receive(:each_list_item)
        end
        expect(Projects::LfsPointers::LfsDownloadService).not_to receive(:new)

        result = subject.execute

        expect(result[:status]).to eq :success
      end
    end

    context 'when an exception is raised' do
      it 'returns error' do
        error_message = "error message"
        expect_next_instance_of(Projects::LfsPointers::LfsObjectDownloadListService) do |instance|
          expect(instance).to receive(:each_list_item).and_raise(StandardError, error_message)
        end

        result = subject.execute

        expect(result[:status]).to eq :error
        expect(result[:message]).to eq error_message
      end
    end

    context 'when an GRPC::Core::CallError exception raised' do
      it 'returns error' do
        error_message = "error message"
        expect_next_instance_of(Projects::LfsPointers::LfsObjectDownloadListService) do |instance|
          expect(instance).to receive(:each_list_item).and_raise(GRPC::Core::CallError, error_message)
        end

        result = subject.execute

        expect(result[:status]).to eq :error
        expect(result[:message]).to eq error_message
      end
    end
  end

  context 'when lfs is not enabled for the project' do
    it 'does not download lfs objects' do
      allow(project).to receive(:lfs_enabled?).and_return(false)
      expect(Projects::LfsPointers::LfsObjectDownloadListService).not_to receive(:new)
      expect(Projects::LfsPointers::LfsDownloadService).not_to receive(:new)

      result = subject.execute

      expect(result[:status]).to eq :success
    end
  end
end
