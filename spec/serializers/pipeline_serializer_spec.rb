require 'spec_helper'

describe PipelineSerializer do
  let(:serializer) do
    described_class.new(user: user)
  end

  let(:pipelines) do
    create_list(:ci_pipeline, 2)
  end

  let(:user) { create(:user) }

  # TODO add some tests here.
end
