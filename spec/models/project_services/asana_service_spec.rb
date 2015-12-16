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
#

require 'spec_helper'

describe AsanaService, models: true do
  describe 'Associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of :api_key }
    end
  end

  describe 'Execute' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }

    before do
      @asana = AsanaService.new
      allow(@asana).to receive_messages(
        project: project,
        project_id: project.id,
        service_hook: true,
        api_key: 'verySecret',
        restrict_to_branch: 'master'
      )
    end

    it 'should call Asana service to created a story' do
      expect(Asana::Task).to receive(:find).with('123456').once

      @asana.check_commit('related to #123456', 'pushed')
    end

    it 'should call Asana service to created a story and close a task' do
      expect(Asana::Task).to receive(:find).with('456789').twice

      @asana.check_commit('fix #456789', 'pushed')
    end

    it 'should be able to close via url' do
      expect(Asana::Task).to receive(:find).with('42').twice

      @asana.check_commit('closes https://app.asana.com/19292/956299/42', 'pushed')
    end

    it 'should allow multiple matches per line' do
      expect(Asana::Task).to receive(:find).with('123').twice
      expect(Asana::Task).to receive(:find).with('456').twice
      expect(Asana::Task).to receive(:find).with('789').once

      expect(Asana::Task).to receive(:find).with('42').once
      expect(Asana::Task).to receive(:find).with('12').twice

      message = <<-EOF
      minor bigfix, refactoring, fixed #123 and Closes #456 work on #789
      ref https://app.asana.com/19292/956299/42 and closing https://app.asana.com/19292/956299/12
      EOF
      @asana.check_commit(message, 'pushed')
    end
  end
end
