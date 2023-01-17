# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupLink::ProjectGroupLinkEntity do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project_group_link) { create(:project_group_link) }

  let(:entity) { described_class.new(project_group_link, { current_user: current_user, source: project_group_link.project }) }

  before do
    allow(entity).to receive(:current_user).and_return(current_user)
  end

  it 'matches json schema' do
    expect(entity.to_json).to match_schema('group_link/project_group_link')
  end

  context 'when current user has `admin_project_member` permissions' do
    before do
      allow(entity).to receive(:can?).with(current_user, :admin_project_group_link, project_group_link).and_return(false)
      allow(entity).to receive(:can?).with(current_user, :admin_project_member, project_group_link.project).and_return(true)
    end

    it 'exposes `can_update` and `can_remove` as `true`' do
      json = entity.as_json

      expect(json[:can_update]).to be true
      expect(json[:can_remove]).to be false
    end
  end

  context 'when current user is a group owner' do
    before do
      allow(entity).to receive(:can?).with(current_user, :admin_project_group_link, project_group_link).and_return(true)
      allow(entity).to receive(:can?).with(current_user, :admin_project_member, project_group_link.project).and_return(false)
    end

    it 'exposes `can_remove` as true' do
      json = entity.as_json

      expect(json[:can_remove]).to be true
    end
  end

  context 'when current user is not a group owner' do
    before do
      allow(entity).to receive(:can?).with(current_user, :admin_project_group_link, project_group_link).and_return(false)
      allow(entity).to receive(:can?).with(current_user, :admin_project_member, project_group_link.project).and_return(false)
    end

    it 'exposes `can_remove` as false' do
      json = entity.as_json

      expect(json[:can_remove]).to be false
    end
  end
end
