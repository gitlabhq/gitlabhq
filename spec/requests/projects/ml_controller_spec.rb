# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MlController, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.first_owner }
  let_it_be(:model1) { create(:ml_models, :with_versions, project: project) }

  let(:read_model_registry) { true }
  let(:write_model_registry) { true }

  let(:params) { {} }

  before do
    allow(Ability).to receive(:allowed?).and_call_original
    allow(Ability).to receive(:allowed?)
                        .with(user, :read_model_registry, project)
                        .and_return(read_model_registry)
    allow(Ability).to receive(:allowed?)
                        .with(user, :write_model_registry, project)
                        .and_return(write_model_registry)

    sign_in(user)
  end

  describe 'POST #preview_markdown' do
    it 'renders json in a correct format' do
      preview_markdown

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(json_response.keys).to match_array(%w[body references])
      expect(json_response['body']).to eq('<p data-sourcepos="1:1-1:4" dir="auto">test</p>')
      expect(json_response['references']).to eq({ "commands" => "", "suggestions" => [], "users" => [] })
    end
  end

  private

  def preview_markdown
    post project_ml_preview_markdown_path(project, params: { text: 'test' })
  end
end
