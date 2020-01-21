# frozen_string_literal: true

RSpec.shared_examples 'correct pipeline information for pipelines for merge requests' do
  context 'when pipeline for merge request' do
    let(:pipeline) { merge_request.all_pipelines.first }

    let(:merge_request) do
      create(:merge_request, :with_detached_merge_request_pipeline,
        source_project: project,
        target_project: project)
    end

    it 'renders a source ref of the pipeline' do
      render

      expect(rendered).to have_content pipeline.source_ref
      expect(rendered).not_to have_content pipeline.ref
    end
  end
end
