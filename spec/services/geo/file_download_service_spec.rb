require 'spec_helper'

describe Geo::FileDownloadService, services: true do
  let!(:primary)  { create(:geo_node, :primary) }
  let(:secondary) { create(:geo_node) }

  before do
    allow(described_class).to receive(:current_node) { secondary }
  end

  describe '#execute' do
    context 'user avatar' do
      let(:user) { create(:user, avatar: fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png')) }
      let(:upload) { Upload.find_by(model: user, uploader: 'AvatarUploader') }

      subject { described_class.new(:avatar, upload.id) }

      it 'downloads an user avatar' do
        allow_any_instance_of(Gitlab::ExclusiveLease)
          .to receive(:try_obtain).and_return(true)
        allow_any_instance_of(Gitlab::Geo::FileTransfer)
          .to receive(:download_from_primary).and_return(100)

        expect{ subject.execute }.to change { Geo::FileRegistry.count }.by(1)
      end
    end

    context 'group avatar' do
      let(:group) { create(:group, avatar: fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png')) }
      let(:upload) { Upload.find_by(model: group, uploader: 'AvatarUploader') }

      subject { described_class.new(:avatar, upload.id) }

      it 'downloads a group avatar' do
        allow_any_instance_of(Gitlab::ExclusiveLease)
          .to receive(:try_obtain).and_return(true)
        allow_any_instance_of(Gitlab::Geo::FileTransfer)
          .to receive(:download_from_primary).and_return(100)

        expect{ subject.execute }.to change { Geo::FileRegistry.count }.by(1)
      end
    end

    context 'project avatar' do
      let(:project) { create(:empty_project, avatar: fixture_file_upload(Rails.root + 'spec/fixtures/dk.png', 'image/png')) }
      let(:upload) { Upload.find_by(model: project, uploader: 'AvatarUploader') }

      subject { described_class.new(:avatar, upload.id) }

      it 'downloads a project avatar' do
        allow_any_instance_of(Gitlab::ExclusiveLease)
          .to receive(:try_obtain).and_return(true)
        allow_any_instance_of(Gitlab::Geo::FileTransfer)
          .to receive(:download_from_primary).and_return(100)

        expect{ subject.execute }.to change { Geo::FileRegistry.count }.by(1)
      end
    end

    context 'LFS object' do
      let(:lfs_object) { create(:lfs_object) }

      subject { described_class.new(:lfs, lfs_object.id) }

      it 'downloads an LFS object' do
        allow_any_instance_of(Gitlab::ExclusiveLease)
          .to receive(:try_obtain).and_return(true)
        allow_any_instance_of(Gitlab::Geo::LfsTransfer)
          .to receive(:download_from_primary).and_return(100)

        expect{ subject.execute }.to change { Geo::FileRegistry.count }.by(1)
      end
    end

    it 'raises an error with bad object type' do
      expect{ described_class.new(:bad, 1).execute }.to raise_error(NameError)
    end
  end
end
