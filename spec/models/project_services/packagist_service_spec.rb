require 'spec_helper'

describe PackagistService do
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  let(:project) { create(:project) }

  let(:packagist_server) { 'https://packagist.example.com' }
  let(:packagist_username) { 'theUser' }
  let(:packagist_token) { 'verySecret' }
  let(:packagist_hook_url) do
    "#{packagist_server}/api/update-package?username=#{packagist_username}&apiToken=#{packagist_token}"
  end

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

  describe '#execute' do
    let(:user)    { create(:user) }
    let(:project) { create(:project, :repository) }
    let(:push_sample_data) { Gitlab::DataBuilder::Push.build_sample(project, user) }
    let(:packagist_service) { described_class.create(packagist_params) }

    before do
      stub_request(:post, packagist_hook_url)
    end

    it 'calls Packagist API' do
      packagist_service.execute(push_sample_data)

      expect(a_request(:post, packagist_hook_url)).to have_been_made.once
    end
  end
end
