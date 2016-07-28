require 'spec_helper'

describe Gitlab::AkismetHelper, type: :helper do
  let(:project) { create(:project, :public) }
  let(:user) { create(:user) }

  before do
    allow(Gitlab.config.gitlab).to receive(:url).and_return(Settings.send(:build_gitlab_url))
    allow_any_instance_of(ApplicationSetting).to receive(:akismet_enabled).and_return(true)
    allow_any_instance_of(ApplicationSetting).to receive(:akismet_api_key).and_return('12345')
  end

  describe '#check_for_spam?' do
    it 'returns true for public project' do
      expect(helper.check_for_spam?(project)).to eq(true)
    end

    it 'returns false for private project' do
      project.update_attribute(:visibility_level, Gitlab::VisibilityLevel::PRIVATE)
      expect(helper.check_for_spam?(project)).to eq(false)
    end
  end

  describe '#is_spam?' do
    it 'returns true for spam' do
      environment = {
        'action_dispatch.remote_ip' => '127.0.0.1',
        'HTTP_USER_AGENT' => 'Test User Agent'
      }

      allow_any_instance_of(::Akismet::Client).to receive(:check).and_return([true, true])
      expect(helper.is_spam?(environment, user, 'Is this spam?')).to eq(true)
    end
  end
end
