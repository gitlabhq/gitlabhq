# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'global_id' do
  it 'prepends `Gitlab::Patch::GlobalId`' do
    expect(GlobalID.ancestors).to include(Gitlab::Patch::GlobalId)
  end

  it 'patches GlobalID to find aliased models when a deprecation exists' do
    allow(Gitlab::GlobalId::Deprecations).to receive(:deprecation_for).and_call_original
    allow(Gitlab::GlobalId::Deprecations).to receive(:deprecation_for).with('Issue').and_return(double(new_model_name: 'Project'))
    project = create(:project)
    gid_string = Gitlab::GlobalId.build(model_name: Issue.name, id: project.id).to_s

    expect(GlobalID.new(gid_string)).to have_attributes(
      to_s: gid_string,
      model_name: 'Project',
      model_class: Project,
      find: project
    )
  end

  it 'works as normal when no deprecation exists' do
    issue = create(:issue)
    gid_string = Gitlab::GlobalId.build(model_name: Issue.name, id: issue.id).to_s

    expect(GlobalID.new(gid_string)).to have_attributes(
      to_s: gid_string,
      model_name: 'Issue',
      model_class: Issue,
      find: issue
    )
  end
end
