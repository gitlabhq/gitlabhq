require 'rails_helper'

describe Appearance do
  subject { build(:appearance) }

  it { include(CacheableAttributes) }
  it { expect(described_class.current_without_cache).to eq(described_class.first) }

  it { is_expected.to have_many(:uploads) }

  describe '#single_appearance_row' do
    it 'adds an error when more than 1 row exists' do
      create(:appearance)

      new_row = build(:appearance)
      new_row.save

      expect(new_row.valid?).to eq(false)
    end
  end

  context 'with uploads' do
    it_behaves_like 'model with mounted uploader', false do
      let(:model_object) { create(:appearance, :with_logo) }
      let(:upload_attribute) { :logo }
      let(:uploader_class) { AttachmentUploader }
    end
  end
end
