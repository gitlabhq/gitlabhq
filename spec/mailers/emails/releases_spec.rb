# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

describe Emails::Releases do
  include EmailSpec::Matchers
  include_context 'gitlab email notification'

  describe '#new_release_email' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }
    let(:release) { create(:release, project: project) }

    subject { Notify.new_release_email(user.id, release) }

    it_behaves_like 'an email sent from GitLab'

    context 'when the release has a name' do
      it 'shows the correct subject' do
        release.name = 'beta-1'
        expected_subject = "#{release.project.name} | New release: #{release.name} - #{release.tag}"
        is_expected.to have_subject(expected_subject)
      end
    end

    context 'when the release does not have a name' do
      it 'shows the correct subject' do
        release.name = nil
        expected_subject = "#{release.project.name} | New release: #{release.tag}"

        is_expected.to have_subject(expected_subject)
      end
    end

    it 'contains a message with the new release tag' do
      message = "A new Release #{release.tag} for #{release.project.name} was published."
      is_expected.to have_body_text(message)
    end

    it 'contains the release assets' do
      is_expected.to have_body_text('Assets:')
      release.sources do |source|
        is_expected.to have_body_text("Download #{source.format}")
      end
    end

    it 'contains the release notes' do
      is_expected.to have_body_text('Release notes:')
      is_expected.to have_body_text(release.description)
    end
  end
end
