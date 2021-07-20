# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Packagist do
  let(:packagist_params) do
    {
        active: true,
        project: project,
        properties: {
            username: packagist_username,
            token: packagist_token,
            server: packagist_server
        }
    }
  end

  let(:packagist_hook_url) do
    "#{packagist_server}/api/update-package?username=#{packagist_username}&apiToken=#{packagist_token}"
  end

  let(:packagist_token) { 'verySecret' }
  let(:packagist_username) { 'theUser' }
  let(:packagist_server) { 'https://packagist.example.com' }
  let(:project) { create(:project) }

  it_behaves_like Integrations::HasWebHook do
    let(:integration) { described_class.new(packagist_params) }
    let(:hook_url) { "#{packagist_server}/api/update-package?username=#{packagist_username}&apiToken=#{packagist_token}" }
  end

  describe '#execute' do
    let(:user)    { create(:user) }
    let(:project) { create(:project, :repository) }
    let(:push_sample_data) { Gitlab::DataBuilder::Push.build_sample(project, user) }
    let(:packagist_integration) { described_class.create!(packagist_params) }

    before do
      stub_request(:post, packagist_hook_url)
    end

    it 'calls Packagist API' do
      packagist_integration.execute(push_sample_data)

      expect(a_request(:post, packagist_hook_url)).to have_been_made.once
    end
  end
end
