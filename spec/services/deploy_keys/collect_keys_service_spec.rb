# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DeployKeys::CollectKeysService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private) }

  subject { DeployKeys::CollectKeysService.new(project, user) }

  before do
    project&.add_developer(user)
  end

  context 'when no project is passed in' do
    let(:project) { nil }

    it 'returns an empty Array' do
      expect(subject.execute).to be_empty
    end
  end

  context 'when no user is passed in' do
    let(:user) { nil }

    it 'returns an empty Array' do
      expect(subject.execute).to be_empty
    end
  end

  context 'when a project is passed in' do
    let_it_be(:deploy_keys_project) { create(:deploy_keys_project, :write_access, project: project) }
    let_it_be(:deploy_key) { deploy_keys_project.deploy_key }

    it 'only returns deploy keys with write access' do
      create(:deploy_keys_project, project: project)

      expect(subject.execute).to contain_exactly(deploy_key)
    end

    it 'returns deploy keys only for this project' do
      other_project = create(:project)
      create(:deploy_keys_project, :write_access, project: other_project)

      expect(subject.execute).to contain_exactly(deploy_key)
    end
  end

  context 'when the user cannot read the project' do
    before do
      project.members.delete_all
    end

    it 'returns an empty Array' do
      expect(subject.execute).to be_empty
    end
  end
end
