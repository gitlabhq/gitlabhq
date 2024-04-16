# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RepositoryCheckMailer do
  include EmailSpec::Matchers

  describe '.notify' do
    it 'emails all admins' do
      admins = create_list(:admin, 3)

      mail = described_class.notify(1)

      expect(mail).to deliver_to admins.map(&:email)
    end

    it 'email with I18n.default_locale' do
      admins = create_list(:admin, 2, preferred_language: :zh_CN)

      mail = described_class.notify(3)

      expect(mail).to deliver_to admins.map(&:email)
      expect(mail).to have_subject 'GitLab Admin | 3 projects failed their last repository check'
    end

    it 'omits blocked admins' do
      blocked = create(:admin, :blocked)
      admins = create_list(:admin, 3)

      mail = described_class.notify(1)

      expect(mail.to).not_to include(blocked.email)
      expect(mail).to deliver_to admins.map(&:email)
    end

    it 'mentions the number of failed checks' do
      mail = described_class.notify(3)

      expect(mail).to have_subject 'GitLab Admin | 3 projects failed their last repository check'
    end

    context 'with footer and header' do
      subject { described_class.notify(1) }

      it_behaves_like 'appearance header and footer enabled'
      it_behaves_like 'appearance header and footer not enabled'
    end
  end
end
