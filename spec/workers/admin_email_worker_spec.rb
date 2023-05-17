# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AdminEmailWorker, feature_category: :source_code_management do
  subject(:worker) { described_class.new }

  describe '.perform' do
    it 'does not attempt to send repository check mail when they are disabled' do
      stub_application_setting(repository_checks_enabled: false)

      expect(worker).not_to receive(:send_repository_check_mail)

      worker.perform
    end

    context 'repository_checks enabled' do
      before do
        stub_application_setting(repository_checks_enabled: true)
      end

      it 'checks if repository check mail should be sent' do
        expect(worker).to receive(:send_repository_check_mail)

        worker.perform
      end

      it 'does not send mail when there are no failed repos' do
        expect(RepositoryCheckMailer).not_to receive(:notify)

        worker.perform
      end

      it 'send mail when there is a failed repo' do
        create(:project, last_repository_check_failed: true, last_repository_check_at: Date.yesterday)

        expect(RepositoryCheckMailer).to receive(:notify).and_return(spy)

        worker.perform
      end
    end
  end
end
