# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::UploadsController, feature_category: :shared do
  include WorkhorseHelpers

  it_behaves_like 'uploads actions' do
    let_it_be(:model) { create(:group, :public) }
    let_it_be(:upload) { create(:upload, :namespace_upload, :with_file, model: model) }

    let(:show_path) { show_group_uploads_path(model, upload.secret, File.basename(upload.path)) }
  end
end
