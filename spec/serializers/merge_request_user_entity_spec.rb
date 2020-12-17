# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestUserEntity do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:request) { EntityRequest.new(project: project, current_user: user) }

  let(:entity) do
    described_class.new(user, request: request)
  end

  context 'as json' do
    subject { entity.as_json }

    it 'exposes needed attributes' do
      expect(subject).to include(:id, :name, :username, :state, :avatar_url, :web_url, :can_merge)
    end
  end
end
