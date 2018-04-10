require 'spec_helper'

describe ProjectBadge do
  let(:placeholder_url) { 'http://www.example.com/%{project_path}/%{project_id}/%{default_branch}/%{commit_sha}' }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
  end

  shared_examples 'rendered_links' do
    it 'should use the badge project information to populate the url placeholders' do
      stub_project_commit_info(project)

      expect(badge.public_send("rendered_#{method}")).to eq "http://www.example.com/#{project.full_path}/#{project.id}/master/whatever"
    end

    def stub_project_commit_info(project)
      allow(project).to receive(:commit).and_return(double('Commit', sha: 'whatever'))
      allow(project).to receive(:default_branch).and_return('master')
    end
  end

  context 'methods' do
    let(:badge) { build(:project_badge, link_url: placeholder_url, image_url: placeholder_url) }
    let!(:project) { badge.project }

    context '#rendered_link_url' do
      let(:method) { :link_url }

      it_behaves_like 'rendered_links'
    end

    context '#rendered_image_url' do
      let(:method) { :image_url }

      it_behaves_like 'rendered_links'
    end
  end
end
