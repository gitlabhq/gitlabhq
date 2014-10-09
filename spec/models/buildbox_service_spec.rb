# == Schema Information
#
# Table name: services
#
#  id         :integer          not null, primary key
#  type       :string(255)
#  title      :string(255)
#  project_id :integer          not null
#  created_at :datetime
#  updated_at :datetime
#  active     :boolean          default(FALSE), not null
#  properties :text
#

require 'spec_helper'

describe BuildboxService do
  describe 'Associations' do
    it { should belong_to :project }
    it { should have_one :service_hook }
  end

  describe 'commits methods' do
    before do
      @project = Project.new
      @project.stub(
        default_branch: 'default-brancho'
      )

      @service = BuildboxService.new
      @service.stub(
        project: @project,
        service_hook: true,
        project_url: 'https://buildbox.io/account-name/example-project',
        token: 'secret-sauce-webhook-token:secret-sauce-status-token'
      )
    end

    describe :webhook_url do
      it 'returns the webhook url' do
        @service.webhook_url.should ==
          'https://webhook.buildbox.io/deliver/secret-sauce-webhook-token'
      end
    end

    describe :commit_status_path do
      it 'returns the correct status page' do
        @service.commit_status_path('2ab7834c').should ==
          'https://gitlab.buildbox.io/status/secret-sauce-status-token.json?commit=2ab7834c'
      end
    end

    describe :build_page do
      it 'returns the correct build page' do
        @service.build_page('2ab7834c').should ==
          'https://buildbox.io/account-name/example-project/builds?commit=2ab7834c'
      end
    end

    describe :builds_page do
      it 'returns the correct path to the builds page' do
        @service.builds_path.should ==
          'https://buildbox.io/account-name/example-project/builds?branch=default-brancho'
      end
    end

    describe :status_img_path do
      it 'returns the correct path to the status image' do
        @service.status_img_path.should == 'https://badge.buildbox.io/secret-sauce-status-token.svg'
      end
    end
  end
end
