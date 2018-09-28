# frozen_string_literal: true

require 'spec_helper'

describe LabelNote do
  set(:project)  { create(:project, :repository) }
  set(:user)   { create(:user) }
  set(:label) { create(:label, project: project) }
  set(:label2) { create(:label, project: project) }
  let(:resource_parent) { project }

  context 'when resource is issue' do
    set(:resource) { create(:issue, project: project) }

    it_behaves_like 'label note created from events'
  end

  context 'when resource is merge request' do
    set(:resource) { create(:merge_request, source_project: project, target_project: project) }

    it_behaves_like 'label note created from events'
  end
end
