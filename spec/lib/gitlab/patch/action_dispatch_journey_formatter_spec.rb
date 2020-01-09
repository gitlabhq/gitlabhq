# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Patch::ActionDispatchJourneyFormatter do
  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: group) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }
  let(:url) { Gitlab::Routing.url_helpers.project_pipeline_url(project, pipeline) }
  let(:expected_path) { "#{project.full_path}/pipelines/#{pipeline.id}" }

  context 'custom implementation of #missing_keys' do
    before do
      expect_any_instance_of(Gitlab::Patch::ActionDispatchJourneyFormatter).to receive(:missing_keys)
    end

    it 'generates correct url' do
      expect(url).to end_with(expected_path)
    end
  end

  context 'original implementation of #missing_keys' do
    before do
      allow_any_instance_of(Gitlab::Patch::ActionDispatchJourneyFormatter).to receive(:missing_keys) do |instance, route, parts|
        instance.send(:old_missing_keys, route, parts) # test the old implementation
      end
    end

    it 'generates correct url' do
      expect(url).to end_with(expected_path)
    end
  end
end
