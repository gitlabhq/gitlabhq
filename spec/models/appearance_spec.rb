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
    it_behaves_like 'model with uploads', false do
      let(:model_object) { create(:appearance, :with_logo) }
      let(:upload_attribute) { :logo }
      let(:uploader_class) { AttachmentUploader }
    end
  end

  shared_examples 'logo paths' do |logo_type|
    let(:appearance) { create(:appearance, "with_#{logo_type}".to_sym) }
    let(:filename) { 'dk.png' }
    let(:expected_path) { "/uploads/-/system/appearance/#{logo_type}/#{appearance.id}/#{filename}" }

    it 'returns nil when there is no upload' do
      expect(subject.send("#{logo_type}_path")).to be_nil
    end

    it 'returns a local path using the system route' do
      expect(appearance.send("#{logo_type}_path")).to eq(expected_path)
    end

    describe 'with asset host configured' do
      let(:asset_host) { 'https://gitlab-assets.example.com' }

      before do
        allow(ActionController::Base).to receive(:asset_host) { asset_host }
      end

      it 'returns a full URL with the system path' do
        expect(appearance.send("#{logo_type}_path")).to eq("#{asset_host}#{expected_path}")
      end
    end
  end

  %i(logo header_logo favicon).each do |logo_type|
    it_behaves_like 'logo paths', logo_type
  end
end
