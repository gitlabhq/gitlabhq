# == Schema Information
#
# Table name: services
#
#  id          :integer          not null, primary key
#  type        :string(255)
#  title       :string(255)
#  project_id  :integer          not null
#  created_at  :datetime
#  updated_at  :datetime
#  active      :boolean          default(FALSE), not null
#  properties  :text
#

require 'spec_helper'

describe AsanaService, models: true do
  describe 'Associations' do
    it { should belong_to :project }
    it { should have_one :service_hook }
  end

  describe 'Validations' do
    context 'active' do
      before do
        subject.active = true
      end

      it { should validate_presence_of :api_key }
    end
  end

  describe 'Execute' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }

    before do
      @asana = AsanaService.new
      @asana.stub(
        project: project,
        project_id: project.id,
        service_hook: true,
        api_key: 'verySecret',
        restrict_to_branch: 'master'
      )
    end

    it 'should call Asana service to created a story' do
      Asana::Task.should_receive(:find).with('123456').once

      @asana.check_commit('related to #123456', 'pushed')
    end

    it 'should call Asana service to created a story and close a task' do
      Asana::Task.should_receive(:find).with('456789').twice

      @asana.check_commit('fix #456789', 'pushed')
    end
  end
end
