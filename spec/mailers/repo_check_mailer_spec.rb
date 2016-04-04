require 'rails_helper'

describe RepoCheckMailer do
  include EmailSpec::Matchers

  describe '.notify' do
    it 'emails all admins' do
      admins = 3.times.map { create(:admin) }

      mail = described_class.notify(1)

      expect(mail).to deliver_to admins.map(&:email)
    end

    it 'mentions the number of failed checks' do
      mail = described_class.notify(3)

      expect(mail).to have_subject '3 projects failed their last repository check'
    end
  end
end
