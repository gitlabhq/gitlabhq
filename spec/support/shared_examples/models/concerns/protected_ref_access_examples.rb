# frozen_string_literal: true

RSpec.shared_examples 'protected ref access' do |association|
  let_it_be(:project) { create(:project) }
  let_it_be(:protected_ref) { create(association, project: project) } # rubocop:disable Rails/SaveBang

  it { is_expected.to validate_inclusion_of(:access_level).in_array(described_class.allowed_access_levels) }

  it { is_expected.to validate_presence_of(:access_level) }

  context 'when not role?' do
    before do
      allow(subject).to receive(:role?).and_return(false)
    end

    it { is_expected.not_to validate_presence_of(:access_level) }
  end

  describe '#check_access' do
    let_it_be(:current_user) { create(:user) }

    let(:access_level) { ::Gitlab::Access::DEVELOPER }

    before_all do
      project.add_maintainer(current_user)
    end

    subject do
      described_class.new(
        association => protected_ref,
        access_level: access_level
      )
    end

    context 'when current_user is nil' do
      it { expect(subject.check_access(nil)).to eq(false) }
    end

    context 'when access_level is NO_ACCESS' do
      let(:access_level) { ::Gitlab::Access::NO_ACCESS }

      it { expect(subject.check_access(current_user)).to eq(false) }
    end

    context 'when current_user can push_code to project and access_level is permitted' do
      before do
        allow(current_user).to receive(:can?).with(:push_code, project).and_return(true)
      end

      it { expect(subject.check_access(current_user)).to eq(true) }
    end

    context 'when current_user cannot push_code to project' do
      before do
        allow(current_user).to receive(:can?).with(:push_code, project).and_return(false)
      end

      it { expect(subject.check_access(current_user)).to eq(false) }
    end
  end
end
