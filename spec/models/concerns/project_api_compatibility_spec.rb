# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectAPICompatibility do
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

  describe '#auto_devops_enabled' do
    where(
      initial: [:missing, nil, false, true],
      final: [nil, false, true]
    )

    with_them do
      before do
        project.build_auto_devops(enabled: initial) unless initial == :missing
      end

      # Implicit auto devops when enabled is nil
      let(:expected) { final.nil? ? true : final }

      it 'sets the correct value' do
        project.update!(auto_devops_enabled: final)

        expect(project.auto_devops_enabled?).to eq(expected)
      end
    end
  end

  describe '#auto_devops_deploy_strategy' do
    where(
      initial: [:missing, *ProjectAutoDevops.deploy_strategies.keys],
      final: ProjectAutoDevops.deploy_strategies.keys
    )

    with_them do
      before do
        project.build_auto_devops(deploy_strategy: initial) unless initial == :missing
      end

      it 'sets the correct value' do
        project.update!(auto_devops_deploy_strategy: final)

        expect(project.auto_devops.deploy_strategy).to eq(final)
      end
    end
  end
end
