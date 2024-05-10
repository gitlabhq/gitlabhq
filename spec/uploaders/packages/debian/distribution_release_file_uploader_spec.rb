# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Debian::DistributionReleaseFileUploader, feature_category: :package_registry do
  [:project, :group].each do |container_type|
    context "Packages::Debian::#{container_type.capitalize}Distribution" do
      let_it_be(:factory) { "debian_#{container_type}_distribution" }
      let_it_be(:distribution) { create(factory, :with_file) }
      let(:uploader) { described_class.new(distribution, :file) }
      let(:path) { Gitlab.config.packages.storage_path }

      subject { uploader }

      it { is_expected.to include_module(Packages::GcsSignedUrlMetadata) }

      it_behaves_like "builds correct paths",
        store_dir: %r[^\h{2}/\h{2}/\h{64}/debian_#{container_type}_distribution/\d+$],
        cache_dir: %r{/packages/tmp/cache$},
        work_dir: %r{/packages/tmp/work$}

      context 'object store is remote' do
        before do
          stub_package_file_object_storage
        end

        include_context 'with storage', described_class::Store::REMOTE

        it_behaves_like "builds correct paths",
          store_dir: %r[^\h{2}/\h{2}/\h{64}/debian_#{container_type}_distribution/\d+$],
          cache_dir: %r{/packages/tmp/cache$},
          work_dir: %r{/packages/tmp/work$}
      end

      describe 'remote file' do
        let(:distribution) { create(factory, :with_file, :object_storage) }

        context 'with object storage enabled' do
          before do
            stub_package_file_object_storage
          end

          it 'can store file remotely' do
            expect(distribution.file_store).to eq(described_class::Store::REMOTE)
            expect(distribution.file.path).not_to be_blank
          end

          it_behaves_like 'augmenting GCS signed URL with metadata' do
            let(:has_project?) { container_type == :project }
          end
        end
      end

      describe '#filename' do
        it { expect(subject.filename).to eq('Release') }

        context 'with signed_file' do
          let(:uploader) { described_class.new(distribution, :signed_file) }

          it { expect(subject.filename).to eq('InRelease') }
        end
      end
    end
  end
end
