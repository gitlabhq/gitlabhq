# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::EmailsOnPush do
  let_it_be(:project) { create_default(:project).freeze }

  describe 'Validations' do
    context 'when integration is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:recipients) }
    end

    context 'when integration is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:recipients) }
    end

    describe 'validates number of recipients' do
      before do
        stub_const("#{described_class}::RECIPIENTS_LIMIT", 2)
      end

      subject(:integration) { described_class.new(project: project, recipients: recipients, active: true) }

      context 'valid number of recipients' do
        let(:recipients) { 'foo@bar.com duplicate@example.com Duplicate@example.com invalid-email' }

        it 'does not count duplicates and invalid emails' do
          is_expected.to be_valid
        end
      end

      context 'invalid number of recipients' do
        let(:recipients) { 'foo@bar.com bar@foo.com bob@gitlab.com' }

        it { is_expected.not_to be_valid }

        it 'adds an error message' do
          integration.valid?

          expect(integration.errors).to contain_exactly('Recipients can\'t exceed 2')
        end

        context 'when integration is not active' do
          before do
            integration.active = false
          end

          it { is_expected.to be_valid }
        end
      end
    end
  end

  describe '.new' do
    context 'when properties is missing branches_to_be_notified' do
      subject { described_class.new(properties: {}) }

      it 'sets the default value to all' do
        expect(subject.branches_to_be_notified).to eq('all')
      end
    end

    context 'when branches_to_be_notified is already set' do
      subject { described_class.new(properties: { branches_to_be_notified: 'protected' }) }

      it 'does not overwrite it with the default value' do
        expect(subject.branches_to_be_notified).to eq('protected')
      end
    end
  end

  describe '.valid_recipients' do
    let(:recipients) { '<invalid> foobar Valid@recipient.com Dup@lica.te dup@lica.te Dup@Lica.te' }

    it 'removes invalid email addresses and removes duplicates by keeping the original capitalization' do
      expect(described_class.valid_recipients(recipients)).to contain_exactly('Valid@recipient.com', 'Dup@lica.te')
    end
  end

  describe '#execute' do
    let(:push_data) { { object_kind: 'push' } }
    let(:project)   { create(:project, :repository) }
    let(:integration) { create(:emails_on_push_integration, project: project) }
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

        integration.execute(push_data)
      end
    end

    shared_examples 'not sending email' do |branches_to_be_notified, branch_being_pushed_to|
      let(:push_data) { { object_kind: 'push', object_attributes: { ref: branch_being_pushed_to } } }

      before do
        subject.branches_to_be_notified = branches_to_be_notified
      end

      it 'does not send email' do
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
