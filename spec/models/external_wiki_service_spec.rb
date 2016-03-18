# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string(255)
#  title                 :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  active                :boolean          default(FALSE), not null
#  properties            :text
#  template              :boolean          default(FALSE)
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#  note_events           :boolean          default(TRUE), not null
#  build_events          :boolean          default(FALSE), not null
#

require 'spec_helper'

describe ExternalWikiService, models: true do
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
        expect(wiki_path).to match('https://gitlab.com')
      end
    end
  end
end
