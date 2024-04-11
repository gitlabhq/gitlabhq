# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AutoDevops::DisableWorker, '#perform', feature_category: :auto_devops do
  let(:user) { create(:user, developer_of: project) }
  let(:project) { create(:project, :repository, :auto_devops) }
  let(:auto_devops) { project.auto_devops }
  let(:pipeline) { create(:ci_pipeline, :failed, :auto_devops_source, project: project, user: user) }

  subject { described_class.new }

  before do
    project.add_developer(user)
    stub_application_setting(auto_devops_enabled: true)
    auto_devops.update_attribute(:enabled, nil)
  end

  it 'disables auto devops for project' do
    subject.perform(pipeline.id)

    expect(auto_devops.reload.enabled).to eq(false)
  end

  context 'when project owner is a user' do
    let(:owner) { create(:user) }
    let(:namespace) { create(:namespace, owner: owner) }
    let(:project) { create(:project, :repository, :auto_devops, namespace: namespace) }

    it 'sends an email to pipeline user and project owner(s)' do
      expect(NotificationService).to receive_message_chain(:new, :autodevops_disabled).with(pipeline, [user.email, owner.email])

      subject.perform(pipeline.id)
    end
  end

  context 'when project does not have owner' do
    let(:group) { create(:group) }
    let(:project) { create(:project, :repository, :auto_devops, namespace: group) }

    it 'sends an email to pipeline user' do
      expect(NotificationService).to receive_message_chain(:new, :autodevops_disabled).with(pipeline, [user.email])

      subject.perform(pipeline.id)
    end
  end

  context 'when pipeline is not related to a user and project does not have owner' do
    let(:group) { create(:group) }
    let(:project) { create(:project, :repository, :auto_devops, namespace: group) }
    let(:pipeline) { create(:ci_pipeline, :failed, project: project) }

    it 'does not send an email' do
      expect(NotificationService).not_to receive(:new)

      subject.perform(pipeline.id)
    end
  end
end
