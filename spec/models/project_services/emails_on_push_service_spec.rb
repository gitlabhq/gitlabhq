# frozen_string_literal: true

require 'spec_helper'

describe EmailsOnPushService do
  describe 'Validations' do
    context 'when service is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:recipients) }
    end

    context 'when service is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:recipients) }
    end
  end

  context 'project emails' do
    let(:push_data) { { object_kind: 'push' } }
    let(:project)   { create(:project, :repository) }
    let(:service)   { create(:emails_on_push_service, project: project) }
    let(:recipients) { 'test@gitlab.com' }

    before do
      subject.recipients = recipients
    end

    shared_examples 'sending email' do |branches_to_be_notified, branch_being_pushed_to|
      let(:push_data) { { object_kind: 'push', object_attributes: { ref: branch_being_pushed_to } } }

      before do
        subject.branches_to_be_notified = branches_to_be_notified
      end

      it 'sends email' do
        expect(EmailsOnPushWorker).not_to receive(:perform_async)

        service.execute(push_data)
      end
    end

    shared_examples 'not sending email' do |branches_to_be_notified, branch_being_pushed_to|
      let(:push_data) { { object_kind: 'push', object_attributes: { ref: branch_being_pushed_to } } }

      before do
        subject.branches_to_be_notified = branches_to_be_notified
      end

      it 'does not send email' do
        expect(EmailsOnPushWorker).not_to receive(:perform_async)

        service.execute(push_data)
      end
    end

    context 'when emails are disabled on the project' do
      it 'does not send emails' do
        expect(project).to receive(:emails_disabled?).and_return(true)
        expect(EmailsOnPushWorker).not_to receive(:perform_async)

        service.execute(push_data)
      end
    end

    context 'when emails are enabled on the project' do
      before do
        create(:protected_branch, project: project, name: 'a-protected-branch')
        expect(project).to receive(:emails_disabled?).and_return(true)
      end

      using RSpec::Parameterized::TableSyntax

      where(:case_name, :branches_to_be_notified, :branch_being_pushed_to, :expected_action) do
        'pushing to a random branch and notification configured for all branches'                           | 'all'                   | 'random'             | 'sending email'
        'pushing to the default branch and notification configured for all branches'                        | 'all'                   | 'master'             | 'sending email'
        'pushing to a protected branch and notification configured for all branches'                        | 'all'                   | 'a-protected-branch' | 'sending email'
        'pushing to a random branch and notification configured for default branch only'                    | 'default'               | 'random'             | 'not sending email'
        'pushing to the default branch and notification configured for default branch only'                 | 'default'               | 'master'             | 'sending email'
        'pushing to a protected branch and notification configured for default branch only'                 | 'default'               | 'a-protected-branch' | 'not sending email'
        'pushing to a random branch and notification configured for protected branches only'                | 'protected'             | 'random'             | 'not sending email'
        'pushing to the default branch and notification configured for protected branches only'             | 'protected'             | 'master'             | 'not sending email'
        'pushing to a protected branch and notification configured for protected branches only'             | 'protected'             | 'a-protected-branch' | 'sending email'
        'pushing to a random branch and notification configured for default and protected branches only'    | 'default_and_protected' | 'random'             | 'not sending email'
        'pushing to the default branch and notification configured for default and protected branches only' | 'default_and_protected' | 'master'             | 'sending email'
        'pushing to a protected branch and notification configured for default and protected branches only' | 'default_and_protected' | 'a-protected-branch' | 'sending email'
      end

      with_them do
        include_examples params[:expected_action], branches_to_be_notified: params[:branches_to_be_notified], branch_being_pushed_to: params[:branch_being_pushed_to]
      end
    end
  end
end
