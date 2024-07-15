# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::MarkdownUploadAdmin, feature_category: :team_planning do
  describe '#as_json' do
    let_it_be(:user) { create(:user) }
    let_it_be(:upload) { create(:upload, :issuable_upload, uploaded_by_user: user) }

    subject { described_class.new(upload).as_json }

    it 'exposes correct attributes' do
      is_expected.to include(
        id: upload.id,
        size: upload.size,
        filename: upload.filename,
        created_at: upload.created_at,
        uploaded_by: {
          id: user.id,
          name: user.name,
          username: user.username
        }
      )
    end
  end
end
