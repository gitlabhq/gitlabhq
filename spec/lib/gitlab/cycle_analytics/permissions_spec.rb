# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::CycleAnalytics::Permissions do
  let(:project) { create(:project, public_builds: false) }
  let(:user) { create(:user) }

  subject { described_class.get(user: user, project: project) }

  context 'user with no relation to the project' do
    it 'has no permissions to issue stage' do
      expect(subject[:issue]).to eq(false)
    end

    it 'has no permissions to test stage' do
      expect(subject[:test]).to eq(false)
    end

    it 'has no permissions to staging stage' do
      expect(subject[:staging]).to eq(false)
    end

    it 'has no permissions to code stage' do
      expect(subject[:code]).to eq(false)
    end

    it 'has no permissions to review stage' do
      expect(subject[:review]).to eq(false)
    end

    it 'has no permissions to plan stage' do
      expect(subject[:plan]).to eq(false)
    end
  end

  context 'user is maintainer' do
    before do
      project.add_maintainer(user)
    end

    it 'has permissions to issue stage' do
      expect(subject[:issue]).to eq(true)
    end

    it 'has permissions to test stage' do
      expect(subject[:test]).to eq(true)
    end

    it 'has permissions to staging stage' do
      expect(subject[:staging]).to eq(true)
    end

    it 'has permissions to code stage' do
      expect(subject[:code]).to eq(true)
    end

    it 'has permissions to review stage' do
      expect(subject[:review]).to eq(true)
    end

    it 'has permissions to plan stage' do
      expect(subject[:plan]).to eq(true)
    end
  end

  context 'user has no build permissions' do
    before do
      project.add_guest(user)
    end

    it 'has permissions to issue stage' do
      expect(subject[:issue]).to eq(true)
    end

    it 'has no permissions to test stage' do
      expect(subject[:test]).to eq(false)
    end

    it 'has no permissions to staging stage' do
      expect(subject[:staging]).to eq(false)
    end
  end

  context 'user has no merge request permissions' do
    before do
      project.add_guest(user)
    end

    it 'has permissions to issue stage' do
      expect(subject[:issue]).to eq(true)
    end

    it 'has no permissions to code stage' do
      expect(subject[:code]).to eq(false)
    end

    it 'has no permissions to review stage' do
      expect(subject[:review]).to eq(false)
    end
  end

  context 'user has no issue permissions' do
    before do
      project.add_developer(user)
      project.project_feature.update_attribute(:issues_access_level, ProjectFeature::DISABLED)
    end

    it 'has permissions to code stage' do
      expect(subject[:code]).to eq(true)
    end

    it 'has no permissions to issue stage' do
      expect(subject[:issue]).to eq(false)
    end
  end
end
