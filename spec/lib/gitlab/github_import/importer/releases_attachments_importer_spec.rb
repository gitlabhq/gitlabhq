# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::ReleasesAttachmentsImporter do
  subject { described_class.new(project, client) }

  let_it_be(:project) { create(:project) }

  let(:client) { instance_double(Gitlab::GithubImport::Client) }

  describe '#each_object_to_import', :clean_gitlab_redis_cache do
    let!(:release_1) { create(:release, project: project) }
    let!(:release_2) { create(:release, project: project) }

    it 'iterates each project release' do
      list = []
      subject.each_object_to_import do |object|
        list << object
      end
      expect(list).to contain_exactly(release_1, release_2)
    end

    context 'when release is already processed' do
      it "doesn't process this release" do
        subject.mark_as_imported(release_1)

        list = []
        subject.each_object_to_import do |object|
          list << object
        end
        expect(list).to contain_exactly(release_2)
      end
    end
  end

  describe '#representation_class' do
    it { expect(subject.representation_class).to eq(Gitlab::GithubImport::Representation::ReleaseAttachments) }
  end

  describe '#importer_class' do
    it { expect(subject.importer_class).to eq(Gitlab::GithubImport::Importer::ReleaseAttachmentsImporter) }
  end

  describe '#sidekiq_worker_class' do
    it { expect(subject.sidekiq_worker_class).to eq(Gitlab::GithubImport::ImportReleaseAttachmentsWorker) }
  end

  describe '#collection_method' do
    it { expect(subject.collection_method).to eq(:release_attachments) }
  end

  describe '#object_type' do
    it { expect(subject.object_type).to eq(:release_attachment) }
  end

  describe '#id_for_already_imported_cache' do
    let(:release) { build_stubbed(:release) }

    it { expect(subject.id_for_already_imported_cache(release)).to eq(release.id) }
  end

  describe '#object_representation' do
    let(:release) { build_stubbed(:release) }

    it 'returns release attachments representation' do
      representation = subject.object_representation(release)

      expect(representation.class).to eq subject.representation_class
      expect(representation.release_db_id).to eq release.id
      expect(representation.description).to eq release.description
    end
  end
end
