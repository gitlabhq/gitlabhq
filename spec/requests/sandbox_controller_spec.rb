# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SandboxController, feature_category: :shared do
  describe 'GET #mermaid' do
    it 'renders page without template' do
      get sandbox_mermaid_path

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(layout: nil)
    end
  end
end
