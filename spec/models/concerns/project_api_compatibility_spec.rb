# frozen_string_literal: true

require 'spec_helper'

describe ProjectAPICompatibility do
  let(:project) { create(:project) }

  it "converts build_git_strategy=fetch to build_allow_git_fetch=true" do
    project.update!(:build_git_strategy, 'fetch')
    expect(project.build_allow_git_fetch).to eq(true)
  end

  it "converts build_git_strategy=clone to build_allow_git_fetch=false" do
    project.update!(:build_git_strategy, 'clone')
    expect(project.build_allow_git_fetch).to eq(false)
  end
end
