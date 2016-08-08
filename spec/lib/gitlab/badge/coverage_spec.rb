require 'spec_helper'

describe Gitlab::Badge::Coverage do
  let(:project) { create(:project) }

  let(:pipeline) do
    create(:ci_pipeline, project: project,
                         sha: project.commit.id,
                         ref: 'master')
  end

  let(:badge) { described_class.new(project, 'master') }

  context 'builds exist' do
  end

  context 'build does not exist' do
  end
end
