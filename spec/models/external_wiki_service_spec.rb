require 'spec_helper'

describe ExternalWikiService do
  include ExternalWikiHelper
  describe "Associations" do
    it { should belong_to :project }
    it { should have_one :service_hook }
  end

  describe "Validations" do
    context "active" do
      before do
        subject.active = true
      end

      it { should validate_presence_of :external_wiki_url }
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

      it 'should replace the wiki url' do
        wiki_path = get_project_wiki_path(project)
        wiki_path.should match('https://gitlab.com')
      end
    end
  end
end
