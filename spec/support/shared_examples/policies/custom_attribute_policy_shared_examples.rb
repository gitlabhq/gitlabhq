# frozen_string_literal: true

RSpec.shared_examples 'custom attribute policy' do
  let(:permissions) { %i[read_custom_attribute update_custom_attribute delete_custom_attribute] }

  context 'when user is admin' do
    let(:current_user) { admin }

    context 'when admin mode is enabled', :enable_admin_mode do
      it { is_expected.to be_allowed(*permissions) }
    end

    context 'when admin mode is disabled' do
      it { is_expected.to be_disallowed(*permissions) }
    end
  end

  context 'when user is not an admin' do
    let(:current_user) { user }

    it { is_expected.to be_disallowed(*permissions) }
  end

  context 'when user is anonymous' do
    let(:current_user) { nil }

    it { is_expected.to be_disallowed(*permissions) }
  end
end
