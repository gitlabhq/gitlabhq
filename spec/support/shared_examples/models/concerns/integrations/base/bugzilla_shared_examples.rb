# frozen_string_literal: true

RSpec.shared_examples Integrations::Base::Bugzilla do
  it_behaves_like Integrations::HasAvatar

  describe 'Validations' do
    context 'when integration is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:project_url) }
      it { is_expected.to validate_presence_of(:issues_url) }
      it { is_expected.to validate_presence_of(:new_issue_url) }

      it_behaves_like 'issue tracker integration URL attribute', :project_url
      it_behaves_like 'issue tracker integration URL attribute', :issues_url
      it_behaves_like 'issue tracker integration URL attribute', :new_issue_url
    end

    context 'when integration is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:project_url) }
      it { is_expected.not_to validate_presence_of(:issues_url) }
      it { is_expected.not_to validate_presence_of(:new_issue_url) }
    end
  end

  describe '#attribution_notice' do
    it 'returns attribution notice' do
      expect(subject.attribution_notice)
        .to eq('The Bugzilla logo is a trademark of the Mozilla Foundation in the U.S. and other countries.')
    end
  end
end
