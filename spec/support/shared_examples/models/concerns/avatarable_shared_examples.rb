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
      it 'shows correct avatar url' do
        url = [Gitlab.config.gitlab.url, model.avatar.url].join
        expect(model.avatar_url).to eq(model.avatar.url)
        expect(model.avatar_url(only_path: false)).to eq(url)
      end
    end
  end
end
