# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RepositoryCheckMailer do
  include EmailSpec::Matchers

  describe '.notify' do
    it 'delivers to the given recipient' do
      admin = create(:admin)

      mail = described_class.notify(1, admin.email)

      expect(mail).to deliver_to(admin.email)
    end

    it 'renders the subject for multiple failed checks' do
      mail = described_class.notify(3, 'admin@example.com')

      expect(mail).to have_subject 'GitLab Admin | 3 projects failed their last repository check'
    end

    context 'with footer and header' do
      subject { described_class.notify(1, 'admin@example.com') }

      it_behaves_like 'appearance header and footer enabled'
      it_behaves_like 'appearance header and footer not enabled'
    end
  end
end
