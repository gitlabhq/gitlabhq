# frozen_string_literal: true

RSpec.shared_examples 'a field with obfuscated email address' do
  let(:resource_parent) { note.project }

  context 'when anonymous' do
    let(:user) { nil }

    it { is_expected.to include(obfuscated_email) }
  end

  context 'with signed in user' do
    before do
      stub_member_access_level(resource_parent, access_level => user) if access_level
    end

    context 'when user has no role in project' do
      let(:access_level) { nil }

      it { is_expected.to include(obfuscated_email) }
    end

    context 'when user has guest role in project' do
      let(:access_level) { :guest }

      it { is_expected.to include(obfuscated_email) }
    end

    context 'when user has reporter role in project' do
      let(:access_level) { :reporter }

      it { is_expected.to include(email) }
    end

    context 'when user has developer role in project' do
      let(:access_level) { :developer }

      it { is_expected.to include(email) }
    end
  end
end
