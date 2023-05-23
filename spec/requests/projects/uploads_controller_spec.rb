# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::UploadsController, feature_category: :shared do
  include WorkhorseHelpers

  it_behaves_like 'uploads actions' do
    let_it_be(:model) { create(:project, :public) }
    let_it_be(:upload) { create(:upload, :issuable_upload, :with_file, model: model) }

    let(:show_path) { show_project_uploads_path(model, upload.secret, File.basename(upload.path)) }
  end
end
