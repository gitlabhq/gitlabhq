# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Emails::Groups do
  include EmailSpec::Matchers

  let(:group) { create(:group) }
  let(:user) { create(:user) }

  before do
    group.add_owner(user)
  end

  describe '#group_was_exported_email' do
    subject { Notify.group_was_exported_email(user, group) }

    it 'sends success email' do
      expect(subject).to have_subject "#{group.name} | Group was exported"
      expect(subject).to have_body_text 'The download link will expire in 24 hours.'
      expect(subject).to have_body_text "groups/#{group.path}/-/download_export"
    end
  end

  describe '#group_was_not_exported_email' do
    let(:shared) { Gitlab::ImportExport::Shared.new(group) }
    let(:error) { Gitlab::ImportExport::Error.new('Error!') }

    before do
      shared.error(error)
    end

    subject { Notify.group_was_not_exported_email(user, group, shared.errors) }

    it 'sends failure email' do
      expect(subject).to have_subject "#{group.name} | Group export error"
      expect(subject).to have_body_text "Group #{group.name} couldn't be exported."
    end
  end
end
