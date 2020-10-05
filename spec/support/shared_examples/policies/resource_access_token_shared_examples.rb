# frozen_string_literal: true

RSpec.shared_examples 'Self-managed Core resource access tokens' do
  before do
    allow(::Gitlab).to receive(:com?).and_return(false)
  end

  context 'with owner' do
    let(:current_user) { owner }

    it { is_expected.to be_allowed(:admin_resource_access_tokens) }
  end

  context 'with developer' do
    let(:current_user) { developer }

    it { is_expected.not_to be_allowed(:admin_resource_access_tokens) }
  end
end

RSpec.shared_examples 'GitLab.com Core resource access tokens' do
  before do
    allow(::Gitlab).to receive(:com?).and_return(true)
    stub_ee_application_setting(should_check_namespace_plan: true)
  end

  context 'with owner' do
    let(:current_user) { owner }

    it { is_expected.not_to be_allowed(:admin_resource_access_tokens) }
  end
end
