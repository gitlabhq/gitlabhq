# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Releases::Links::DestroyService, feature_category: :release_orchestration do
  let(:service) { described_class.new(release, user, {}) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, developer_of: project) }
  let_it_be(:release) { create(:release, project: project, author: user, tag: 'v1.1.0') }

  let!(:release_link) do
    create(
      :release_link,
      release: release,
      name: 'awesome-app.dmg',
      url: 'https://example.com/download/awesome-app.dmg'
    )
  end

  describe '#execute' do
    subject(:execute) { service.execute(release_link) }

    it 'successfully deletes a release link' do
      expect { execute }.to change { release.links.count }.by(-1)

      is_expected.to be_success
    end

    context 'when user does not have access to delete release link' do
      before do
        project.add_guest(user)
      end

      it 'returns an error' do
        expect { execute }.not_to change { release.links.count }

        is_expected.to be_error
        expect(execute.message).to include('Access Denied')
        expect(execute.reason).to eq(:forbidden)
      end
    end

    context 'when release link does not exist' do
      let(:release_link) { nil }

      it 'returns an error' do
        expect { execute }.not_to change { release.links.count }

        is_expected.to be_error
        expect(execute.message).to eq('Link does not exist')
        expect(execute.reason).to eq(:not_found)
      end
    end

    context 'when release link deletion failed' do
      before do
        allow(release_link).to receive(:destroy).and_return(false)
      end

      it 'returns an error' do
        expect { execute }.not_to change { release.links.count }

        is_expected.to be_error
        expect(execute.reason).to eq(:bad_request)
      end
    end
  end
end
