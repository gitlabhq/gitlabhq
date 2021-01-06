# frozen_string_literal: true

RSpec.shared_examples 'concerning versionless param' do
  let_it_be(:versionless_package) { create(:maven_package, project: project, version: nil) }

  it { is_expected.not_to include(versionless_package) }

  context 'with valid include_versionless param' do
    let(:params) { { include_versionless: true } }

    it { is_expected.to include(versionless_package) }
  end

  context 'with empty include_versionless param' do
    let(:params) { { include_versionless: '' } }

    it { is_expected.not_to include(versionless_package) }
  end
end
