# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TriggerVariableEntity do
  let(:project) { create(:project) }
  let(:request) { double('request') }
  let(:user) { create(:user) }
  let(:variable) { { key: 'TEST_KEY', value: 'TEST_VALUE' } }

  subject { described_class.new(variable, request: request).as_json }

  before do
    allow(request).to receive(:current_user).and_return(user)
    allow(request).to receive(:project).and_return(project)
  end

  it 'exposes the variable key' do
    expect(subject).to include(:key)
  end

  context 'when user has access to the value' do
    context 'when user is maintainer' do
      before do
        project.team.add_maintainer(user)
      end

      it 'exposes the variable value' do
        expect(subject).to include(:value)
      end
    end

    context 'when user is owner' do
      let(:user) { project.first_owner }

      it 'exposes the variable value' do
        expect(subject).to include(:value)
      end
    end
  end

  context 'when user does not have access to the value' do
    before do
      project.team.add_developer(user)
    end

    it 'does not expose the variable value' do
      expect(subject).not_to include(:value)
    end
  end
end
