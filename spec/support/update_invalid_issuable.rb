shared_examples 'update invalid issuable' do |klass|
  let(:params) do
    {
      namespace_id: project.namespace.path,
      project_id: project.path,
      id: issuable.iid
    }
  end

  let(:issuable) do
    klass == Issue ? issue : merge_request
  end

  before do
    if klass == Issue
      params.merge!(issue: { title: "any" })
    else
      params.merge!(merge_request: { title: "any" })
    end
  end

  context 'when updating causes conflicts' do
    before do
      allow_any_instance_of(issuable.class).to receive(:save)
        .and_raise(ActiveRecord::StaleObjectError.new(issuable, :save))
    end

    it 'renders edit when format is html' do
      put :update, params

      expect(response).to render_template(:edit)
      expect(assigns[:conflict]).to be_truthy

      if klass == MergeRequest && issuable.requires_approve?
        expect(assigns[:suggested_approvers]).to be_an(Array)
      end
    end

    it 'renders json error message when format is json' do
      params[:format] = "json"

      put :update, params

      expect(response.status).to eq(409)
      expect(JSON.parse(response.body)).to have_key('errors')
    end
  end

  context 'when updating an invalid issuable' do
    before do
      key = klass == Issue ? :issue : :merge_request
      params[key][:title] = ""
    end

    it 'renders edit when merge request is invalid' do
      put :update, params

      expect(response).to render_template(:edit)
    end
  end
end
