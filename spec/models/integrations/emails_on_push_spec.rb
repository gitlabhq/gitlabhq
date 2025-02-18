# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::EmailsOnPush, feature_category: :integrations do
  it_behaves_like Integrations::Base::EmailsOnPush

  describe '#execute' do
    let_it_be(:project) { create(:project, :repository) }

    let(:push_data) { { object_kind: 'push' } }
    let(:recipients) { 'test@gitlab.com' }

    subject(:integration) { create(:emails_on_push_integration, project: project, recipients: recipients) }

    shared_examples 'sending email' do |branches_to_be_notified, branch_being_pushed_to|
      let(:push_data) { { object_kind: 'push', object_attributes: { ref: branch_being_pushed_to } } }

      it 'sends email' do
        integration.update!(branches_to_be_notified: branches_to_be_notified)

        expect(EmailsOnPushWorker).not_to receive(:perform_async)

        integration.execute(push_data)
      end
    end

    shared_examples 'not sending email' do |branches_to_be_notified, branch_being_pushed_to|
      let(:push_data) { { object_kind: 'push', object_attributes: { ref: branch_being_pushed_to } } }

      it 'does not send email' do
        integration.update!(branches_to_be_notified: branches_to_be_notified)

        expect(EmailsOnPushWorker).not_to receive(:perform_async)

        integration.execute(push_data)
      end
    end

    context 'when emails are disabled on the project' do
      it 'does not send emails' do
        expect(project).to receive(:emails_disabled?).and_return(true)
        expect(EmailsOnPushWorker).not_to receive(:perform_async)

        integration.execute(push_data)
      end
    end

    context 'when emails are enabled on the project' do
      before do
        project = create(:project)
        create(:protected_branch, project: project, name: 'a-protected-branch')
        allow(project).to receive(:emails_disabled?).and_return(true)
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
