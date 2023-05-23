# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UploadsController, feature_category: :shared do
  include WorkhorseHelpers

  it_behaves_like 'uploads actions' do
    let_it_be(:model) { create(:personal_snippet, :public) }
    let_it_be(:upload) { create(:upload, :personal_snippet_upload, :with_file, model: model) }

    # See config/routes/uploads.rb
    let(:show_path) do
      "/uploads/-/system/#{model.model_name.singular}/#{model.to_param}/#{upload.secret}/#{File.basename(upload.path)}"
    end
  end
end
