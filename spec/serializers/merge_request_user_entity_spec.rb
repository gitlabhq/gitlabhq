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

    context 'when `status` is not preloaded' do
      it 'does not expose the availability attribute' do
        expect(subject).not_to include(:availability)
      end
    end

    context 'when `status` is preloaded' do
      before do
        user.create_status!(availability: :busy)

        user.status # make sure `status` is loaded
      end

      it 'exposes the availibility attribute' do
        expect(subject[:availability]).to eq('busy')
      end
    end
  end
end
