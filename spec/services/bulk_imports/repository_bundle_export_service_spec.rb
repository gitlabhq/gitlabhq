# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::RepositoryBundleExportService do
  let(:project) { build(:project) }
  let(:export_path) { Dir.mktmpdir }

  subject(:service) { described_class.new(project, export_path) }

  after do
    FileUtils.remove_entry(export_path) if Dir.exist?(export_path)
  end

  describe '#execute' do
    context 'when repository exists' do
      it 'bundles repository to disk' do
        allow(project.repository).to receive(:exists?).and_return(true)
        expect(project.repository).to receive(:bundle_to_disk).with(File.join(export_path, 'project.bundle'))

        service.execute
      end
    end

    context 'when repository does not exist' do
      it 'does not bundle repository to disk' do
        allow(project.repository).to receive(:exists?).and_return(false)
        expect(project.repository).not_to receive(:bundle_to_disk)

        service.execute
      end
    end
  end
end
