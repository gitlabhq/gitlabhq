# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Releases::Links::UpdateService, feature_category: :release_orchestration do
  let(:service) { described_class.new(release, user, params) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user, developer_of: project) }
  let_it_be(:release) { create(:release, project: project, author: user, tag: 'v1.1.0') }

  let(:release_link) do
    create(
      :release_link,
      release: release,
      name: 'awesome-app.dmg',
      url: 'https://example.com/download/awesome-app.dmg'
    )
  end

  let(:params) { { name: name, url: url, direct_asset_path: direct_asset_path, link_type: link_type } }
  let(:name) { 'link' }
  let(:url) { 'https://example.com' }
  let(:direct_asset_path) { '/path' }
  let(:link_type) { 'other' }

  describe '#execute' do
    subject(:execute) { service.execute(release_link) }

    let(:updated_link) { execute.payload[:link] }

    it 'successfully updates a release link' do
      is_expected.to be_success

      expect(updated_link).to have_attributes(
        name: name,
        url: url,
        filepath: direct_asset_path,
        link_type: link_type
      )
    end

    context 'when user does not have access to update release link' do
      before do
        project.add_guest(user)
      end

      it 'returns an error' do
        is_expected.to be_error
        expect(execute.message).to include('Access Denied')
        expect(execute.reason).to eq(:forbidden)
      end
    end

    context 'when url is invalid' do
      let(:url) { 'not_a_url' }

      it 'returns an error' do
        is_expected.to be_error
        expect(execute.message[0]).to include('Url is blocked')
        expect(execute.reason).to eq(:bad_request)
      end
    end

    context 'when both direct_asset_path and filepath are provided' do
      let(:params) { super().merge(filepath: '/filepath') }

      it 'prefers direct_asset_path' do
        is_expected.to be_success

        expect(updated_link.filepath).to eq(direct_asset_path)
      end
    end

    context 'when only filepath is set' do
      let(:params) { super().merge(filepath: '/filepath') }
      let(:direct_asset_path) { nil }

      it 'uses filepath' do
        is_expected.to be_success

        expect(updated_link.filepath).to eq('/filepath')
      end
    end
  end
end
