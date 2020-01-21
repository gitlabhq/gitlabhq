# frozen_string_literal: true

require 'spec_helper'

describe Uploads::Local do
  let(:data_store) { described_class.new }

  before do
    stub_uploads_object_storage(FileUploader)
  end

  context 'model with uploads' do
    let(:project) { create(:project) }
    let(:relation) { project.uploads }

    describe '#keys' do
      let!(:uploads) { create_list(:upload, 2, uploader: FileUploader, model: project) }

      subject { data_store.keys(relation) }

      it 'returns keys' do
        is_expected.to match_array(relation.map(&:absolute_path))
      end
    end

    describe '#delete_keys' do
      let(:keys) { data_store.keys(relation) }
      let!(:uploads) { create_list(:upload, 2, :with_file, :issuable_upload, model: project) }

      subject { data_store.delete_keys(keys) }

      it 'deletes multiple data' do
        paths = relation.map(&:absolute_path)

        paths.each do |path|
          expect(File.exist?(path)).to be_truthy
        end

        subject

        paths.each do |path|
          expect(File.exist?(path)).to be_falsey
        end
      end
    end
  end
end
