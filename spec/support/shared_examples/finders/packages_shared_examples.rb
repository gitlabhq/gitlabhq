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

RSpec.shared_examples 'concerning package statuses' do
  let_it_be(:hidden_package) { create(:maven_package, :hidden, project: project) }
  let_it_be(:error_package) { create(:maven_package, :error, project: project) }

  context 'displayable packages' do
    it { is_expected.not_to include(hidden_package) }
    it { is_expected.to include(error_package) }
  end

  context 'with status param' do
    let(:params) { { status: :hidden } }

    it { is_expected.to match_array([hidden_package]) }
  end

  context 'with invalid status param' do
    let(:params) { { status: 'invalid_status' } }

    it { expect { subject }.to raise_exception(described_class::InvalidStatusError) }
  end
end
