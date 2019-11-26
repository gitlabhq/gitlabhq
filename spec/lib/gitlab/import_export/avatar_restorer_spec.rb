# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::AvatarRestorer do
  include UploadHelpers

  let(:shared) { project.import_export_shared }
  let(:project) { create(:project) }

  after do
    project.remove_avatar!
  end

  context 'with avatar' do
    before do
      allow_any_instance_of(described_class).to receive(:avatar_export_file)
                                                  .and_return(uploaded_image_temp_path)
    end

    it 'restores a project avatar' do
      expect(described_class.new(project: project, shared: shared).restore).to be true
    end

    it 'saves the avatar into the project' do
      described_class.new(project: project, shared: shared).restore

      expect(project.reload.avatar.file.exists?).to be true
    end
  end

  it 'does not break if there is just a directory' do
    Dir.mktmpdir do |tmpdir|
      FileUtils.mkdir_p("#{tmpdir}/a/b")

      allow_any_instance_of(described_class).to receive(:avatar_export_path)
                                                  .and_return("#{tmpdir}/a")

      expect(described_class.new(project: project, shared: shared).restore).to be true
    end
  end
end
