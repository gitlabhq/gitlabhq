require 'spec_helper'

describe ExternalWikiService do
  include ExternalWikiHelper
  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'when service is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:external_wiki_url) }
      it_behaves_like 'issue tracker service URL attribute', :external_wiki_url
    end

    context 'when service is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:external_wiki_url) }
    end
  end

  describe 'External wiki' do
    let(:project) { create(:project) }

    context 'when it is active' do
      before do
        properties = { 'external_wiki_url' => 'https://gitlab.com' }
        @service = project.create_external_wiki_service(active: true, properties: properties)
      end

      after do
        @service.destroy!
      end

      it 'replaces the wiki url' do
        wiki_path = get_project_wiki_path(project)
        expect(wiki_path).to match('https://gitlab.com')
      end
    end
  end
end
