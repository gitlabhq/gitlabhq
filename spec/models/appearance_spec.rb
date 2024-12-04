# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Appearance do
  using RSpec::Parameterized::TableSyntax
  subject { build(:appearance) }

  it { include(CacheableAttributes) }
  it { expect(described_class.current_without_cache).to eq(described_class.first) }

  it { is_expected.to have_many(:uploads) }

  describe 'default values' do
    subject(:appearance) { described_class.new }

    it { expect(appearance.title).to eq('') }
    it { expect(appearance.description).to eq('') }
    it { expect(appearance.pwa_name).to eq('') }
    it { expect(appearance.pwa_short_name).to eq('') }
    it { expect(appearance.pwa_description).to eq('') }
    it { expect(appearance.member_guidelines).to eq('') }
    it { expect(appearance.new_project_guidelines).to eq('') }
    it { expect(appearance.profile_image_guidelines).to eq('') }
    it { expect(appearance.header_message).to eq('') }
    it { expect(appearance.footer_message).to eq('') }
    it { expect(appearance.message_background_color).to eq('#E75E40') }
    it { expect(appearance.message_font_color).to eq('#FFFFFF') }
    it { expect(appearance.email_header_and_footer_enabled).to eq(false) }
    it { expect(Appearance::ALLOWED_PWA_ICON_SCALER_WIDTHS).to match_array([192, 512]) }
  end

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

  %i[logo header_logo pwa_icon favicon].each do |logo_type|
    it_behaves_like 'logo paths', logo_type
  end

  shared_examples 'icon paths sized' do |width|
    let_it_be(:appearance) { create(:appearance, :with_pwa_icon) }
    let_it_be(:filename) { 'dk.png' }
    let_it_be(:expected_path) { "/uploads/-/system/appearance/pwa_icon/#{appearance.id}/#{filename}?width=#{width}" }

    it 'returns icon path with size parameter' do
      expect(appearance.pwa_icon_path_scaled(width)).to eq(expected_path)
    end
  end

  it_behaves_like 'icon paths sized', 192
  it_behaves_like 'icon paths sized', 512

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

  shared_examples 'validation allows' do
    it { is_expected.to allow_value(value).for(attribute) }
  end

  shared_examples 'validation permits with message' do
    it { is_expected.not_to allow_value(value).for(attribute).with_message(message) }
  end

  context 'valid pwa attributes' do
    where(:attribute, :value) do
      :pwa_name        | nil
      :pwa_name        | ("G" * 255)
      :pwa_short_name  | nil
      :pwa_short_name  | ("S" * 255)
      :pwa_description | nil
      :pwa_description | ("T" * 2048)
    end

    with_them do
      it_behaves_like 'validation allows'
    end
  end

  context 'invalid pwa attributes' do
    where(:attribute, :value, :message) do
      :pwa_name        | ("G" * 256)  | 'is too long (maximum is 255 characters)'
      :pwa_short_name  | ("S" * 256)  | 'is too long (maximum is 255 characters)'
      :pwa_description | ("T" * 2049) | 'is too long (maximum is 2048 characters)'
    end

    with_them do
      it_behaves_like 'validation permits with message'
    end
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

  describe '#uploads_sharding_key' do
    it 'returns epmty hash' do
      appearance = build_stubbed(:appearance)

      expect(appearance.uploads_sharding_key).to eq({})
    end
  end
end
