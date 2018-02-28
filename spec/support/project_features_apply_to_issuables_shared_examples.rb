shared_examples 'project features apply to issuables' do |klass|
  let(:described_class) { klass }

  let(:group) { create(:group) }
  let(:user_in_group) { create(:group_member, :developer, user: create(:user), group: group ).user }
  let(:user_outside_group) { create(:user) }

  let(:project) { create(:project, :public, project_args) }

  def project_args
    feature = "#{described_class.model_name.plural}_access_level".to_sym

    args = { group: group }
    args[feature] = access_level

    args
  end

  before do
    _ = issuable
    gitlab_sign_in(user) if user
    visit path
  end

  context 'public access level' do
    let(:access_level) { ProjectFeature::ENABLED }

    context 'group member' do
      let(:user) { user_in_group }

      it { expect(page).to have_content(issuable.title) }
    end

    context 'non-member' do
      let(:user) { user_outside_group }

      it { expect(page).to have_content(issuable.title) }
    end
  end

  context 'private access level' do
    let(:access_level) { ProjectFeature::PRIVATE }

    context 'group member' do
      let(:user) { user_in_group }

      it { expect(page).to have_content(issuable.title) }
    end

    context 'non-member' do
      let(:user) { user_outside_group }

      it { expect(page).not_to have_content(issuable.title) }
    end
  end
end
