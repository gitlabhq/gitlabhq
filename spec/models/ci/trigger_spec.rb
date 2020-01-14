# frozen_string_literal: true

require 'spec_helper'

describe Ci::Trigger do
  let(:project) { create :project }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:owner) }
    it { is_expected.to have_many(:trigger_requests) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:owner) }
  end

  describe 'before_validation' do
    it 'sets an random token if none provided' do
      trigger = create(:ci_trigger_without_token, project: project)

      expect(trigger.token).not_to be_nil
    end

    it 'does not set a random token if one provided' do
      trigger = create(:ci_trigger, project: project, token: 'token')

      expect(trigger.token).to eq('token')
    end
  end

  describe '#short_token' do
    let(:trigger) { create(:ci_trigger, token: '12345678') }

    subject { trigger.short_token }

    it 'returns shortened token' do
      is_expected.to eq('1234')
    end
  end

  describe '#can_access_project?' do
    let(:owner) { create(:user) }
    let(:trigger) { create(:ci_trigger, owner: owner, project: project) }

    subject { trigger.can_access_project? }

    context 'and is member of the project' do
      before do
        project.add_developer(owner)
      end

      it { is_expected.to eq(true) }
    end

    context 'and is not member of the project' do
      it { is_expected.to eq(false) }
    end
  end
end
