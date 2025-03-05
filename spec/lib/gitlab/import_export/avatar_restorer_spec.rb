# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::AvatarRestorer, :clean_gitlab_redis_shared_state, feature_category: :importers do
  include UploadHelpers

  let(:shared) { project.import_export_shared }
  let(:project) { create(:project) }

  after do
    project.remove_avatar!
  end

  context 'with avatar' do
    before do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:avatar_export_file).and_return(uploaded_image_temp_path)
      end
    end

    it 'restores a project avatar' do
      expect(described_class.new(project: project, shared: shared).restore).to be true
    end

    it 'saves the avatar into the project' do
      described_class.new(project: project, shared: shared).restore

      expect(project.reload.avatar.file.exists?).to be true
    end

    describe 'progress tracking' do
      subject(:restorer) { described_class.new(project: project, shared: shared) }

      it 'tracks processed avatar' do
        restorer.restore

        expect(
          restorer.processed_entry?(
            scope: { project_id: project.id },
            data: 'avatar'
          )
        ).to be(true)
      end

      context 'when avatar is already processed' do
        it 'does not process avatar again' do
          restorer.restore

          expect(restorer).not_to receive(:save_processed_entry)

          restorer.restore
        end
      end
    end
  end

  it 'does not break if there is just a directory' do
    Dir.mktmpdir do |tmpdir|
      FileUtils.mkdir_p("#{tmpdir}/a/b")

      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:avatar_export_path).and_return("#{tmpdir}/a")
      end

      expect(described_class.new(project: project, shared: shared).restore).to be true
    end
  end
end
