# frozen_string_literal: true

RSpec.shared_examples Avatarable do
  describe '#avatar_type' do
    it 'is true if avatar is image' do
      model.update_attribute(:avatar, 'uploads/avatar.png')

      expect(model.avatar_type).to be_truthy
    end

    it 'is false if avatar is html page' do
      model.update_attribute(:avatar, 'uploads/avatar.html')
      model.avatar_type

      msg = 'file format is not supported. Please try one of the following supported formats: ' \
            'png, jpg, jpeg, gif, bmp, tiff, ico, webp'
      expect(model.errors.added?(:avatar, msg)).to be true
    end
  end

  describe '#avatar_url' do
    context 'when avatar file is uploaded' do
      it 'shows correct avatar url', :aggregate_failures do
        version_suffix = model.respond_to?(:updated_at) && model.updated_at ? "?v=#{model.updated_at.to_i}" : ""
        expected_path = model.avatar.url + version_suffix
        expected_url = [Gitlab.config.gitlab.url, expected_path].join

        expect(model.avatar_url).to eq(expected_path)
        expect(model.avatar_url(only_path: false)).to eq(expected_url)
      end
    end
  end

  context 'when batch loading the avatar' do
    it 'uses partition pruning to load the avatar' do
      avatar_upload = Upload.where(model: model).where(uploader: AvatarUploader.name).first!
      expect(avatar_upload.model_type).to eq(model.class.polymorphic_name)

      expect do
        # When the model is first created, the avatar is set directly and bypasses the upload loader
        model.reload.avatar_url
      end.to make_queries_matching(/SELECT .* "uploads"."model_type" = '#{avatar_upload.model_type}'/)
    end
  end
end
