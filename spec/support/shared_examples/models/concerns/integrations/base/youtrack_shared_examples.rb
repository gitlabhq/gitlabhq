# frozen_string_literal: true

RSpec.shared_examples Integrations::Base::Youtrack do
  it_behaves_like Integrations::HasAvatar

  describe 'Validations' do
    context 'when integration is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:project_url) }
      it { is_expected.to validate_presence_of(:issues_url) }

      it_behaves_like 'issue tracker integration URL attribute', :project_url
      it_behaves_like 'issue tracker integration URL attribute', :issues_url
    end

    context 'when integration is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:project_url) }
      it { is_expected.not_to validate_presence_of(:issues_url) }
    end
  end

  describe '#reference_pattern' do
    it_behaves_like 'allows project key on reference pattern'

    it 'does allow project prefix on the reference' do
      expect(subject.reference_pattern.match('YT-123')[:issue]).to eq('YT-123')
    end

    it 'allows lowercase project key on the reference' do
      expect(subject.reference_pattern.match('yt-123')[:issue]).to eq('yt-123')
    end
  end

  describe '#fields' do
    it 'only returns the project_url and issues_url fields' do
      expect(subject.fields.pluck(:name)).to eq(%w[project_url issues_url])
    end
  end

  describe '#attribution_notice' do
    it 'returns attribution notice' do
      expect(subject.attribution_notice)
        .to eq('Copyright © 2024 JetBrains s.r.o. JetBrains YouTrack and the JetBrains YouTrack logo are registered ' \
          'trademarks of JetBrains s.r.o.')
    end
  end
end
