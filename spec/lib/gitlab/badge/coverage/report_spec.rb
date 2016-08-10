require 'spec_helper'

describe Gitlab::Badge::Coverage::Report do
  let(:project) { create(:project) }

  let(:pipeline) do
    create(:ci_pipeline, project: project,
                         sha: project.commit.id,
                         ref: 'master')
  end

  let(:badge) do
    described_class.new(project, 'master')
  end

  context 'builds exist' do
  end

  context 'builds do not exist' do
  end
end
