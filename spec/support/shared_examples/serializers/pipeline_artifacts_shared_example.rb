# frozen_string_literal: true
RSpec.shared_examples 'public artifacts' do
  let_it_be(:project) { create(:project, :public) }
  let(:pipeline) { create(:ci_empty_pipeline, status: :success, project: project) }

  context 'that has artifacts' do
    let!(:build) { create(:ci_build, :success, :artifacts, pipeline: pipeline) }

    it 'contains information about artifacts' do
      expect(subject[:details][:artifacts].length).to eq(1)
    end
  end

  context 'that has non public artifacts' do
    let!(:build) { create(:ci_build, :success, :artifacts, :non_public_artifacts, pipeline: pipeline) }

    it 'does not contain information about artifacts' do
      expect(subject[:details][:artifacts].length).to eq(0)
    end
  end
end
