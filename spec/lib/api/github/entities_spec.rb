# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Github::Entities do
  describe API::Github::Entities::User do
    let(:user) { create(:user, username: username) }
    let(:username) { 'name_of_user' }
    let(:gitlab_protocol_and_host) { "#{Gitlab.config.gitlab.protocol}://#{Gitlab.config.gitlab.host}" }
    let(:expected_user_url) { "#{gitlab_protocol_and_host}/#{username}" }
    let(:entity) { described_class.new(user) }

    subject { entity.as_json }

    specify :aggregate_failure do
      expect(subject[:id]).to eq user.id
      expect(subject[:login]).to eq 'name_of_user'
      expect(subject[:url]).to eq expected_user_url
      expect(subject[:html_url]).to eq expected_user_url
      expect(subject[:avatar_url]).to include('https://www.gravatar.com/avatar')
    end

    context 'with avatar' do
      let(:user) { create(:user, :with_avatar, username: username) }

      specify do
        expect(subject[:avatar_url]).to include("#{gitlab_protocol_and_host}/uploads/-/system/user/avatar/")
      end
    end
  end
end
