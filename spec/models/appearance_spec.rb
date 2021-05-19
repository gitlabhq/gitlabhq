# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Appearance do
  subject { build(:appearance) }

  it { include(CacheableAttributes) }
  it { expect(described_class.current_without_cache).to eq(described_class.first) }

  it { is_expected.to have_many(:uploads) }

  describe '#single_appearance_row' do
    it 'adds an error when more than 1 row exists' do
      create(:appearance)

      new_row = build(:appearance)
      expect { new_row.save! }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Only 1 appearances row can exist')

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

    it 'returns the path when the upload has been orphaned' do
      appearance.send(logo_type).upload.destroy!
      appearance.reload

      expect(appearance.send("#{logo_type}_path")).to eq(expected_path)
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

  describe 'validations' do
    let(:triplet) { '#000' }
    let(:hex)     { '#AABBCC' }

    it { is_expected.to allow_value(nil).for(:message_background_color) }
    it { is_expected.to allow_value(triplet).for(:message_background_color) }
    it { is_expected.to allow_value(hex).for(:message_background_color) }
    it { is_expected.not_to allow_value('000').for(:message_background_color) }

    it { is_expected.to allow_value(nil).for(:message_font_color) }
    it { is_expected.to allow_value(triplet).for(:message_font_color) }
    it { is_expected.to allow_value(hex).for(:message_font_color) }
    it { is_expected.not_to allow_value('000').for(:message_font_color) }
  end

  describe 'email_header_and_footer_enabled' do
    context 'default email_header_and_footer_enabled flag value' do
      it 'returns email_header_and_footer_enabled as true' do
        appearance = build(:appearance)

        expect(appearance.email_header_and_footer_enabled?).to eq(false)
      end
    end

    context 'when setting email_header_and_footer_enabled flag value' do
      it 'returns email_header_and_footer_enabled as true' do
        appearance = build(:appearance, email_header_and_footer_enabled: true)

        expect(appearance.email_header_and_footer_enabled?).to eq(true)
      end
    end
  end
end
