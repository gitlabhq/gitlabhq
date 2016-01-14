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

    def create_data_for_commits(*messages)
      {
        object_kind: 'push',
        ref: 'master',
        user_name: user.name,
        commits: messages.map do |m|
          {
            message: m,
            url: 'https://gitlab.com/',
          }
        end
      }
    end

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

    it 'should call Asana service to create a story' do
      data = create_data_for_commits('Message from commit. related to #123456')
      expected_message = "#{data[:user_name]} pushed to branch #{data[:ref]} of #{project.name_with_namespace} ( #{data[:commits][0][:url]} ): #{data[:commits][0][:message]}"

      d1 = double('Asana::Task')
      expect(d1).to receive(:add_comment).with(text: expected_message)
      expect(Asana::Task).to receive(:find_by_id).with(anything, '123456').once.and_return(d1)

      @asana.execute(data)
    end

    it 'should call Asana service to create a story and close a task' do
      data = create_data_for_commits('fix #456789')
      d1 = double('Asana::Task')
      expect(d1).to receive(:add_comment)
      expect(d1).to receive(:update).with(completed: true)
      expect(Asana::Task).to receive(:find_by_id).with(anything, '456789').once.and_return(d1)

      @asana.execute(data)
    end

    it 'should be able to close via url' do
      data = create_data_for_commits('closes https://app.asana.com/19292/956299/42')
      d1 = double('Asana::Task')
      expect(d1).to receive(:add_comment)
      expect(d1).to receive(:update).with(completed: true)
      expect(Asana::Task).to receive(:find_by_id).with(anything, '42').once.and_return(d1)

      @asana.execute(data)
    end

    it 'should allow multiple matches per line' do
      message = <<-EOF
      minor bigfix, refactoring, fixed #123 and Closes #456 work on #789
      ref https://app.asana.com/19292/956299/42 and closing https://app.asana.com/19292/956299/12
      EOF
      data = create_data_for_commits(message)
      d1 = double('Asana::Task')
      expect(d1).to receive(:add_comment)
      expect(d1).to receive(:update).with(completed: true)
      expect(Asana::Task).to receive(:find_by_id).with(anything, '123').once.and_return(d1)

      d2 = double('Asana::Task')
      expect(d2).to receive(:add_comment)
      expect(d2).to receive(:update).with(completed: true)
      expect(Asana::Task).to receive(:find_by_id).with(anything, '456').once.and_return(d2)

      d3 = double('Asana::Task')
      expect(d3).to receive(:add_comment)
      expect(Asana::Task).to receive(:find_by_id).with(anything, '789').once.and_return(d3)

      d4 = double('Asana::Task')
      expect(d4).to receive(:add_comment)
      expect(Asana::Task).to receive(:find_by_id).with(anything, '42').once.and_return(d4)

      d5 = double('Asana::Task')
      expect(d5).to receive(:add_comment)
      expect(d5).to receive(:update).with(completed: true)
      expect(Asana::Task).to receive(:find_by_id).with(anything, '12').once.and_return(d5)

      @asana.execute(data)
    end
  end
end
