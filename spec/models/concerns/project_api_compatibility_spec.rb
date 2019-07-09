# frozen_string_literal: true

require 'spec_helper'

describe ProjectAPICompatibility do
  let(:project) { create(:project) }

  # git_strategy
  it "converts build_git_strategy=fetch to build_allow_git_fetch=true" do
    project.update!(build_git_strategy: 'fetch')
    expect(project.build_allow_git_fetch).to eq(true)
  end

  it "converts build_git_strategy=clone to build_allow_git_fetch=false" do
    project.update!(build_git_strategy: 'clone')
    expect(project.build_allow_git_fetch).to eq(false)
  end

  # auto_devops_enabled
  it "converts auto_devops_enabled=false to auto_devops_enabled?=false" do
    expect(project.auto_devops_enabled?).to eq(true)
    project.update!(auto_devops_enabled: false)
    expect(project.auto_devops_enabled?).to eq(false)
  end

  it "converts auto_devops_enabled=true to auto_devops_enabled?=true" do
    expect(project.auto_devops_enabled?).to eq(true)
    project.update!(auto_devops_enabled: true)
    expect(project.auto_devops_enabled?).to eq(true)
  end

  # auto_devops_deploy_strategy
  it "converts auto_devops_deploy_strategy=timed_incremental to auto_devops.deploy_strategy=timed_incremental" do
    expect(project.auto_devops).to be_nil
    project.update!(auto_devops_deploy_strategy: 'timed_incremental')
    expect(project.auto_devops.deploy_strategy).to eq('timed_incremental')
  end
end
