# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Debian::ComponentFileUploader, feature_category: :package_registry do
  [:project, :group].each do |container_type|
    context "Packages::Debian::#{container_type.capitalize}ComponentFile" do
      let_it_be(:factory) { "debian_#{container_type}_component_file" }
      let_it_be(:component_file) { create(:"#{factory}") }
      let(:uploader) { described_class.new(component_file, :file) }
      let(:path) { Gitlab.config.packages.storage_path }

      subject { uploader }

      it { is_expected.to include_module(Packages::GcsSignedUrlMetadata) }

      it_behaves_like "builds correct paths",
        store_dir: %r[^\h{2}/\h{2}/\h{64}/debian_#{container_type}_component_file/\d+$],
        cache_dir: %r{/packages/tmp/cache$},
        work_dir: %r{/packages/tmp/work$}

      context 'object store is remote' do
        before do
          stub_package_file_object_storage
        end

        include_context 'with storage', described_class::Store::REMOTE

        it_behaves_like "builds correct paths",
          store_dir: %r[^\h{2}/\h{2}/\h{64}/debian_#{container_type}_component_file/\d+$],
          cache_dir: %r{/packages/tmp/cache$},
          work_dir: %r{/packages/tmp/work$}
      end

      describe 'remote file' do
        let(:component_file) { create(factory, :object_storage) }

        context 'with object storage enabled' do
          before do
            stub_package_file_object_storage
          end

          it 'can store file remotely' do
            expect(component_file.file_store).to eq(described_class::Store::REMOTE)
            expect(component_file.file.path).not_to be_blank
          end

          it_behaves_like 'augmenting GCS signed URL with metadata' do
            let(:has_project?) { container_type == :project }
          end
        end
      end
    end
  end
end
