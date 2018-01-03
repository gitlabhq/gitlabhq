require 'spec_helper'

describe Gitlab::Ci::Status::Pipeline::Common do
  let(:user) { create(:user) }
  let(:project) { create(:project, :private) }
  let(:pipeline) { create(:ci_pipeline, project: project) }

  subject do
    Gitlab::Ci::Status::Core
      .new(pipeline, user)
      .extend(described_class)
  end

  describe '#has_action?' do
    it { is_expected.not_to have_action }
  end

  describe '#has_details?' do
    context 'when user has access to read pipeline' do
      before do
        project.add_developer(user)
      end

      it { is_expected.to have_details }
    end

    context 'when user does not have access to read pipeline' do
      it { is_expected.not_to have_details }
    end
  end

  describe '#details_path' do
    it 'links to the pipeline details page' do
      expect(subject.details_path)
        .to include "pipelines/#{pipeline.id}"
    end
  end
end
