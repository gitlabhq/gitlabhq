# frozen_string_literal: true

require 'spec_helper'

describe ObjectStorage::MigrateUploadsWorker do
  let(:model_class) { Project }
  let(:uploads) { Upload.all }
  let(:to_store) { ObjectStorage::Store::REMOTE }

  def perform(uploads, store = nil)
    described_class.new.perform(uploads.ids, model_class.to_s, mounted_as, store || to_store)
  rescue ObjectStorage::MigrateUploadsWorker::Report::MigrationFailures
    # swallow
  end

  context "for AvatarUploader" do
    let!(:projects) { create_list(:project, 10, :with_avatar) }
    let(:mounted_as) { :avatar }

    before do
      stub_uploads_object_storage(AvatarUploader)
    end

    it_behaves_like "uploads migration worker"

    describe "limits N+1 queries" do
      it "to N*5" do
        query_count = ActiveRecord::QueryRecorder.new { perform(uploads) }

        more_projects = create_list(:project, 3, :with_avatar)

        expected_queries_per_migration = 5 * more_projects.count
        expect { perform(Upload.all) }.not_to exceed_query_limit(query_count).with_threshold(expected_queries_per_migration)
      end
    end
  end

  context "for FileUploader" do
    let!(:projects) { create_list(:project, 10) }
    let(:secret) { SecureRandom.hex }
    let(:mounted_as) { nil }

    def upload_file(project)
      uploader = FileUploader.new(project)
      uploader.store!(fixture_file_upload('spec/fixtures/doc_sample.txt'))
    end

    before do
      stub_uploads_object_storage(FileUploader)

      projects.map(&method(:upload_file))
    end

    it_behaves_like "uploads migration worker"

    describe "limits N+1 queries" do
      it "to N*5" do
        query_count = ActiveRecord::QueryRecorder.new { perform(uploads) }

        more_projects = create_list(:project, 3)
        more_projects.map(&method(:upload_file))

        expected_queries_per_migration = 5 * more_projects.count
        expect { perform(Upload.all) }.not_to exceed_query_limit(query_count).with_threshold(expected_queries_per_migration)
      end
    end
  end

  context 'for DesignManagement::DesignV432x230Uploader' do
    let(:model_class) { DesignManagement::Action }
    let!(:design_actions) { create_list(:design_action, 10, :with_image_v432x230) }
    let(:mounted_as) { :image_v432x230 }

    before do
      stub_uploads_object_storage(DesignManagement::DesignV432x230Uploader)
    end

    it_behaves_like 'uploads migration worker'
  end
end
