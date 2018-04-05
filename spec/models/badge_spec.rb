require 'spec_helper'

describe Badge do
  let(:placeholder_url) { 'http://www.example.com/%{project_path}/%{project_id}/%{default_branch}/%{commit_sha}' }

  describe 'validations' do
    # Requires the let variable url_sym
    shared_examples 'placeholder url' do
      let(:badge) { build(:badge) }

      it 'allows url with http protocol' do
        badge[url_sym] = 'http://www.example.com'

        expect(badge).to be_valid
      end

      it 'allows url with https protocol' do
        badge[url_sym] = 'https://www.example.com'

        expect(badge).to be_valid
      end

      it 'cannot be empty' do
        badge[url_sym] = ''

        expect(badge).not_to be_valid
      end

      it 'cannot be nil' do
        badge[url_sym] = nil

        expect(badge).not_to be_valid
      end

      it 'accept badges placeholders' do
        badge[url_sym] = placeholder_url

        expect(badge).to be_valid
      end

      it 'sanitize url' do
        badge[url_sym] = 'javascript:alert(1)'

        expect(badge).not_to be_valid
      end
    end

    context 'link_url format' do
      let(:url_sym) { :link_url }

      it_behaves_like 'placeholder url'
    end

    context 'image_url format' do
      let(:url_sym) { :image_url }

      it_behaves_like 'placeholder url'
    end
  end

  shared_examples 'rendered_links' do
    it 'should use the project information to populate the url placeholders' do
      stub_project_commit_info(project)

      expect(badge.public_send("rendered_#{method}", project)).to eq "http://www.example.com/#{project.full_path}/#{project.id}/master/whatever"
    end

    it 'returns the url if the project used is nil' do
      expect(badge.public_send("rendered_#{method}", nil)).to eq placeholder_url
    end

    def stub_project_commit_info(project)
      allow(project).to receive(:commit).and_return(double('Commit', sha: 'whatever'))
      allow(project).to receive(:default_branch).and_return('master')
    end
  end

  context 'methods' do
    let(:badge) { build(:badge, link_url: placeholder_url, image_url: placeholder_url) }
    let!(:project) { create(:project) }

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
