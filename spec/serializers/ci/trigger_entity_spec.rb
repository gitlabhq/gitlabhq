# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TriggerEntity, feature_category: :continuous_integration do
  let(:project) { create(:project) }
  let(:trigger) { create(:ci_trigger, project: project, token: '237f3604900a4cd71ed06ef13e57b96d') }
  let(:user) { create(:user) }
  let(:entity) { described_class.new(trigger, current_user: user, project: project) }

  describe '#as_json' do
    let(:as_json) { entity.as_json }
    let(:project_trigger_path) { "/#{project.full_path}/-/triggers/#{trigger.id}" }

    it 'contains required fields' do
      expect(as_json).to include(
        :id, :description, :owner, :last_used, :token, :has_token_exposed, :can_access_project
      )
    end

    it 'contains user fields' do
      expect(as_json[:owner].to_json).to match_schema('entities/user')
    end

    context 'when current user can manage triggers' do
      before do
        project.add_maintainer(user)
      end

      it 'returns short_token as token' do
        expect(as_json[:token]).to eq(trigger.short_token)
      end

      it 'contains project_trigger_path' do
        expect(as_json[:project_trigger_path]).to eq(project_trigger_path)
      end

      it 'returns has_token_exposed' do
        expect(as_json[:has_token_exposed]).to eq(false)
      end
    end

    context 'when current user is the owner of the trigger' do
      before do
        project.add_maintainer(user)
        trigger.update!(owner: user)
      end

      it 'returns token as token' do
        expect(as_json[:token]).to eq(trigger.token)
      end

      it 'contains project_trigger_path' do
        expect(as_json[:project_trigger_path]).to eq(project_trigger_path)
      end

      it 'returns has_token_exposed' do
        expect(as_json[:has_token_exposed]).to eq(true)
      end
    end
  end
end
