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

  context 'with uploads' do
    it_behaves_like 'model with uploads', false do
      let(:model_object) { create(:organization_detail) }
      let(:upload_attribute) { :avatar }
      let(:uploader_class) { AttachmentUploader }
    end
  end
end
