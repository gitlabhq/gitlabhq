# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LabelNote do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let_it_be(:label) { create(:label, project: project) }
  let_it_be(:label2) { create(:label, project: project) }

  let(:resource_parent) { project }

  context 'when resource is issue' do
    let_it_be(:resource) { create(:issue, project: project) }

    it_behaves_like 'label note created from events'
  end

  context 'when resource is merge request' do
    let_it_be(:resource) { create(:merge_request, source_project: project, target_project: project) }

    it_behaves_like 'label note created from events'
  end
end
