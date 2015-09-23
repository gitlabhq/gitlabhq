require 'rails_helper'

describe 'help/index' do
  describe 'version information' do
    it 'is hidden from guests' do
      stub_user(nil)
      stub_version('8.0.2', 'abcdefg')
      stub_helpers

      render

      expect(rendered).not_to match '8.0.2'
      expect(rendered).not_to match 'abcdefg'
    end

    it 'is shown to users' do
      stub_user
      stub_version('8.0.2', 'abcdefg')
      stub_helpers

      render

      expect(rendered).to match '8.0.2'
      expect(rendered).to match 'abcdefg'
    end
  end

  def stub_user(user = double)
    allow(view).to receive(:user_signed_in?).and_return(user)
  end

  def stub_version(version, revision)
    stub_const('Gitlab::VERSION', version)
    stub_const('Gitlab::REVISION', revision)
  end

  def stub_helpers
    allow(view).to receive(:markdown).and_return('')
    allow(view).to receive(:version_status_badge).and_return('')
  end
end
