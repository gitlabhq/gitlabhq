# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe Emails::Imports, feature_category: :importers do
  include EmailSpec::Matchers

  let(:errors) { { 'gist_id1' => "Title can't be blank", 'gist_id2' => 'Snippet maximum file count exceeded' } }
  let(:user) { build_stubbed(:user) }

  describe '#github_gists_import_errors_email' do
    subject { Notify.github_gists_import_errors_email('user_id', errors) }

    before do
      allow(User).to receive(:find).and_return(user)
    end

    it 'sends success email' do
      expect(subject).to have_subject('GitHub Gists import finished with errors')
      expect(subject).to have_content('GitHub gists that were not imported:')
      expect(subject).to have_content("Gist with id gist_id1 failed due to error: Title can't be blank.")
      expect(subject).to have_content('Gist with id gist_id2 failed due to error: Snippet maximum file count exceeded.')
    end

    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'
  end
end
