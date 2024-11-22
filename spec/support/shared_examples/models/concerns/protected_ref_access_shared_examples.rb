# frozen_string_literal: true

RSpec.shared_examples 'protected ref access' do
  include ExternalAuthorizationServiceHelpers

  include_context 'for protected ref access'

  describe 'validations' do
    subject { build(described_factory) }

    context 'when role?' do
      it { is_expected.to validate_inclusion_of(:access_level).in_array(described_class.allowed_access_levels) }

      it { is_expected.to validate_presence_of(:access_level) }

      it do
        is_expected.to validate_uniqueness_of(:access_level).scoped_to(protected_ref_fk)
      end
    end

    context 'when not role?' do
      before do
        allow(subject).to receive(:role?).and_return(false)
      end

      it { is_expected.not_to validate_presence_of(:access_level) }

      it { is_expected.not_to validate_inclusion_of(:access_level).in_array(described_class.allowed_access_levels) }

      it do
        is_expected.not_to validate_uniqueness_of(:access_level).scoped_to(protected_ref_fk)
      end
    end
  end

  describe 'scopes' do
    describe '::for_role' do
      subject(:for_role) { described_class.for_role }

      let_it_be(:developer_access) { create(described_factory, :developer_access) }
      let_it_be(:maintainer_access) { create(described_factory, :maintainer_access) }

      it 'includes all role based access levels' do
        expect(for_role).to contain_exactly(developer_access, maintainer_access)
      end
    end
  end

  describe '::human_access_levels' do
    subject { described_class.human_access_levels }

    let(:levels) do
      {
        Gitlab::Access::DEVELOPER => "Developers + Maintainers",
        Gitlab::Access::MAINTAINER => "Maintainers",
        Gitlab::Access::ADMIN => 'Instance admins',
        Gitlab::Access::NO_ACCESS => "No one"
      }.slice(*described_class.allowed_access_levels)
    end

    it { is_expected.to eq(levels) }
  end

  describe '#check_access(user, current_project)' do
    let_it_be(:current_user) { create(:user) }

    let(:access_level) { ::Gitlab::Access::DEVELOPER }
    let(:current_project) { project }

    before_all do
      project.add_developer(current_user)
    end

    subject(:check_access) do
      described_class
        .new(protected_ref_name => protected_ref, access_level: access_level)
        .check_access(current_user, current_project)
    end

    context 'when current_user is nil' do
      let(:current_user) { nil }

      it { is_expected.to eq false }
    end

    context 'when access_level is NO_ACCESS' do
      let(:access_level) { ::Gitlab::Access::NO_ACCESS }

      it { is_expected.to eq false }
    end

    context 'when instance admin access is configured' do
      let(:access_level) { Gitlab::Access::ADMIN }

      context 'when current_user is a maintainer' do
        before_all do
          project.add_maintainer(current_user)
        end

        it { is_expected.to eq false }
      end

      context 'when current_user is admin' do
        before do
          allow(current_user).to receive(:admin?).and_return(true)
        end

        it { is_expected.to eq true }
      end
    end

    context 'when current_user can push_code to project' do
      context 'and member access is high enough' do
        it { is_expected.to eq true }

        context 'when external authorization denies access' do
          before do
            external_service_deny_access(current_user, project)
          end

          it { is_expected.to eq false }
        end
      end

      context 'and member access is too low' do
        let(:access_level) { ::Gitlab::Access::MAINTAINER }

        it { is_expected.to eq false }
      end
    end

    context 'when current_user cannot push_code to project' do
      before do
        allow(current_user).to receive(:can?).with(:push_code, project).and_return(false)
      end

      it { is_expected.to eq false }
    end
  end
end
