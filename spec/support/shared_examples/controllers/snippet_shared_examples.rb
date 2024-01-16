# frozen_string_literal: true

RSpec.shared_examples 'snippets views' do
  let(:params) { {} }

  before do
    sign_in(user)
  end

  context 'when rendered' do
    render_views

    it 'avoids N+1 database queries' do
      # Warming call to load everything non snippet related
      get(:index, params: params)

      project = create(:project, namespace: user.namespace)
      create(:project_snippet, project: project, author: user)

      control = ActiveRecord::QueryRecorder.new { get(:index, params: params) }

      project = create(:project, namespace: user.namespace)
      create(:project_snippet, project: project, author: user)

      expect { get(:index, params: params) }.not_to exceed_query_limit(control)
    end
  end
end
