# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::OrganizationDetail, type: :model, feature_category: :cell do
  describe 'associations' do
    it { is_expected.to belong_to(:organization).inverse_of(:organization_detail) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:organization) }
    it { is_expected.to validate_length_of(:description).is_at_most(1024) }
  end

  it_behaves_like Avatarable do
    let(:model) { create(:organization_detail) }
  end

  describe '#description_html' do
    let_it_be(:model) { create(:organization_detail, description: '### Foo **Bar**') }
    let(:expected_description) { ' Foo <strong>Bar</strong> ' }

    subject { model.description_html }

    it { is_expected.to eq_no_sourcepos(expected_description) }
  end

  context 'with uploads' do
    it_behaves_like 'model with uploads', false do
      let(:model_object) { create(:organization_detail) }
      let(:upload_attribute) { :avatar }
      let(:uploader_class) { AttachmentUploader }
    end
  end

  describe '#uploads_sharding_key' do
    it 'returns organization_id' do
      organization_detail = build_stubbed(:organization_detail)

      expect(organization_detail.uploads_sharding_key).to eq(organization_id: organization_detail.organization_id)
    end
  end
end
