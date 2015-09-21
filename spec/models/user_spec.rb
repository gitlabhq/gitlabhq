# == Schema Information
#
# Table name: users
#
#  id                         :integer          not null, primary key
#  email                      :string(255)      default(""), not null
#  encrypted_password         :string(255)      default(""), not null
#  reset_password_token       :string(255)
#  reset_password_sent_at     :datetime
#  remember_created_at        :datetime
#  sign_in_count              :integer          default(0)
#  current_sign_in_at         :datetime
#  last_sign_in_at            :datetime
#  current_sign_in_ip         :string(255)
#  last_sign_in_ip            :string(255)
#  created_at                 :datetime
#  updated_at                 :datetime
#  name                       :string(255)
#  admin                      :boolean          default(FALSE), not null
#  projects_limit             :integer          default(10)
#  skype                      :string(255)      default(""), not null
#  linkedin                   :string(255)      default(""), not null
#  twitter                    :string(255)      default(""), not null
#  authentication_token       :string(255)
#  theme_id                   :integer          default(1), not null
#  bio                        :string(255)
#  failed_attempts            :integer          default(0)
#  locked_at                  :datetime
#  username                   :string(255)
#  can_create_group           :boolean          default(TRUE), not null
#  can_create_team            :boolean          default(TRUE), not null
#  state                      :string(255)
#  color_scheme_id            :integer          default(1), not null
#  notification_level         :integer          default(1), not null
#  password_expires_at        :datetime
#  created_by_id              :integer
#  last_credential_check_at   :datetime
#  avatar                     :string(255)
#  confirmation_token         :string(255)
#  confirmed_at               :datetime
#  confirmation_sent_at       :datetime
#  unconfirmed_email          :string(255)
#  hide_no_ssh_key            :boolean          default(FALSE)
#  website_url                :string(255)      default(""), not null
#  notification_email         :string(255)
#  hide_no_password           :boolean          default(FALSE)
#  password_automatically_set :boolean          default(FALSE)
#  location                   :string(255)
#  encrypted_otp_secret       :string(255)
#  encrypted_otp_secret_iv    :string(255)
#  encrypted_otp_secret_salt  :string(255)
#  otp_required_for_login     :boolean          default(FALSE), not null
#  otp_backup_codes           :text
#  public_email               :string(255)      default(""), not null
#  dashboard                  :integer          default(0)
#  project_view               :integer          default(0)
#

require 'spec_helper'

describe User do
  include Gitlab::CurrentSettings

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Gitlab::ConfigHelper) }
    it { is_expected.to include_module(Gitlab::CurrentSettings) }
    it { is_expected.to include_module(Referable) }
    it { is_expected.to include_module(Sortable) }
    it { is_expected.to include_module(TokenAuthenticatable) }
  end

  describe 'associations' do
    it { is_expected.to have_one(:namespace) }
    it { is_expected.to have_many(:snippets).class_name('Snippet').dependent(:destroy) }
    it { is_expected.to have_many(:project_members).dependent(:destroy) }
    it { is_expected.to have_many(:groups) }
    it { is_expected.to have_many(:keys).dependent(:destroy) }
    it { is_expected.to have_many(:events).class_name('Event').dependent(:destroy) }
    it { is_expected.to have_many(:recent_events).class_name('Event') }
    it { is_expected.to have_many(:issues).dependent(:destroy) }
    it { is_expected.to have_many(:notes).dependent(:destroy) }
    it { is_expected.to have_many(:assigned_issues).dependent(:destroy) }
    it { is_expected.to have_many(:merge_requests).dependent(:destroy) }
    it { is_expected.to have_many(:assigned_merge_requests).dependent(:destroy) }
    it { is_expected.to have_many(:identities).dependent(:destroy) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to validate_presence_of(:projects_limit) }
    it { is_expected.to validate_numericality_of(:projects_limit) }
    it { is_expected.to allow_value(0).for(:projects_limit) }
    it { is_expected.not_to allow_value(-1).for(:projects_limit) }

    it { is_expected.to validate_length_of(:bio).is_within(0..255) }

    describe 'email' do
      it 'accepts info@example.com' do
        user = build(:user, email: 'info@example.com')
        expect(user).to be_valid
      end

      it 'accepts info+test@example.com' do
        user = build(:user, email: 'info+test@example.com')
        expect(user).to be_valid
      end

      it "accepts o'reilly@example.com" do
        user = build(:user, email: "o'reilly@example.com")
        expect(user).to be_valid
      end

      it 'rejects test@test@example.com' do
        user = build(:user, email: 'test@test@example.com')
        expect(user).to be_invalid
      end

      it 'rejects mailto:test@example.com' do
        user = build(:user, email: 'mailto:test@example.com')
        expect(user).to be_invalid
      end

      it "rejects lol!'+=?><#$%^&*()@gmail.com" do
        user = build(:user, email: "lol!'+=?><#$%^&*()@gmail.com")
        expect(user).to be_invalid
      end

      context 'when no signup domains listed' do
        before { allow(current_application_settings).to receive(:restricted_signup_domains).and_return([]) }
        it 'accepts any email' do
          user = build(:user, email: "info@example.com")
          expect(user).to be_valid
        end
      end

      context 'when a signup domain is listed and subdomains are allowed' do
        before { allow(current_application_settings).to receive(:restricted_signup_domains).and_return(['example.com', '*.example.com']) }
        it 'accepts info@example.com' do
          user = build(:user, email: "info@example.com")
          expect(user).to be_valid
        end

        it 'accepts info@test.example.com' do
          user = build(:user, email: "info@test.example.com")
          expect(user).to be_valid
        end

        it 'rejects example@test.com' do
          user = build(:user, email: "example@test.com")
          expect(user).to be_invalid
        end
      end

      context 'when a signup domain is listed and subdomains are not allowed' do
        before { allow(current_application_settings).to receive(:restricted_signup_domains).and_return(['example.com']) }

        it 'accepts info@example.com' do
          user = build(:user, email: "info@example.com")
          expect(user).to be_valid
        end

        it 'rejects info@test.example.com' do
          user = build(:user, email: "info@test.example.com")
          expect(user).to be_invalid
        end

        it 'rejects example@test.com' do
          user = build(:user, email: "example@test.com")
          expect(user).to be_invalid
        end
      end
    end
  end

  describe "Respond to" do
    it { is_expected.to respond_to(:is_admin?) }
    it { is_expected.to respond_to(:name) }
    it { is_expected.to respond_to(:private_token) }
  end

  describe '#confirm' do
    let(:user) { create(:user, confirmed_at: nil, unconfirmed_email: 'test@gitlab.com') }

    it 'returns unconfirmed' do
      expect(user.confirmed?).to be_falsey
    end

    it 'confirms a user' do
      user.confirm
      expect(user.confirmed?).to be_truthy
    end
  end

  describe '#to_reference' do
    let(:user) { create(:user) }

    it 'returns a String reference to the object' do
      expect(user.to_reference).to eq "@#{user.username}"
    end
  end

  describe '#generate_password' do
    it "should execute callback when force_random_password specified" do
      user = build(:user, force_random_password: true)
      expect(user).to receive(:generate_password)
      user.save
    end

    it "should not generate password by default" do
      user = create(:user, password: 'abcdefghe')
      expect(user.password).to eq('abcdefghe')
    end

    it "should generate password when forcing random password" do
      allow(Devise).to receive(:friendly_token).and_return('123456789')
      user = create(:user, password: 'abcdefg', force_random_password: true)
      expect(user.password).to eq('12345678')
    end
  end

  describe 'authentication token' do
    it "should have authentication token" do
      user = create(:user)
      expect(user.authentication_token).not_to be_blank
    end
  end

  describe '#disable_two_factor!' do
    it 'clears all 2FA-related fields' do
      user = create(:user, :two_factor)

      expect(user).to be_two_factor_enabled
      expect(user.encrypted_otp_secret).not_to be_nil
      expect(user.otp_backup_codes).not_to be_nil

      user.disable_two_factor!

      expect(user).not_to be_two_factor_enabled
      expect(user.encrypted_otp_secret).to be_nil
      expect(user.encrypted_otp_secret_iv).to be_nil
      expect(user.encrypted_otp_secret_salt).to be_nil
      expect(user.otp_backup_codes).to be_nil
    end
  end

  describe 'projects' do
    before do
      @user = create :user
      @project = create :project, namespace: @user.namespace
      @project_2 = create :project, group: create(:group) # Grant MASTER access to the user
      @project_3 = create :project, group: create(:group) # Grant DEVELOPER access to the user

      @project_2.team << [@user, :master]
      @project_3.team << [@user, :developer]
    end

    it { expect(@user.authorized_projects).to include(@project) }
    it { expect(@user.authorized_projects).to include(@project_2) }
    it { expect(@user.authorized_projects).to include(@project_3) }
    it { expect(@user.owned_projects).to include(@project) }
    it { expect(@user.owned_projects).not_to include(@project_2) }
    it { expect(@user.owned_projects).not_to include(@project_3) }
    it { expect(@user.personal_projects).to include(@project) }
    it { expect(@user.personal_projects).not_to include(@project_2) }
    it { expect(@user.personal_projects).not_to include(@project_3) }
  end

  describe 'groups' do
    before do
      @user = create :user
      @group = create :group
      @group.add_owner(@user)
    end

    it { expect(@user.several_namespaces?).to be_truthy }
    it { expect(@user.authorized_groups).to eq([@group]) }
    it { expect(@user.owned_groups).to eq([@group]) }
    it { expect(@user.namespaces).to match_array([@user.namespace, @group]) }
  end

  describe 'group multiple owners' do
    before do
      @user = create :user
      @user2 = create :user
      @group = create :group
      @group.add_owner(@user)

      @group.add_user(@user2, GroupMember::OWNER)
    end

    it { expect(@user2.several_namespaces?).to be_truthy }
  end

  describe 'namespaced' do
    before do
      @user = create :user
      @project = create :project, namespace: @user.namespace
    end

    it { expect(@user.several_namespaces?).to be_falsey }
    it { expect(@user.namespaces).to eq([@user.namespace]) }
  end

  describe 'blocking user' do
    let(:user) { create(:user, name: 'John Smith') }

    it "should block user" do
      user.block
      expect(user.blocked?).to be_truthy
    end
  end

  describe '.filter' do
    let(:user) { double }

    it 'filters by active users by default' do
      expect(User).to receive(:active).and_return([user])

      expect(User.filter(nil)).to include user
    end

    it 'filters by admins' do
      expect(User).to receive(:admins).and_return([user])

      expect(User.filter('admins')).to include user
    end

    it 'filters by blocked' do
      expect(User).to receive(:blocked).and_return([user])

      expect(User.filter('blocked')).to include user
    end

    it 'filters by two_factor_disabled' do
      expect(User).to receive(:without_two_factor).and_return([user])

      expect(User.filter('two_factor_disabled')).to include user
    end

    it 'filters by two_factor_enabled' do
      expect(User).to receive(:with_two_factor).and_return([user])

      expect(User.filter('two_factor_enabled')).to include user
    end

    it 'filters by wop' do
      expect(User).to receive(:without_projects).and_return([user])

      expect(User.filter('wop')).to include user
    end
  end

  describe :not_in_project do
    before do
      User.delete_all
      @user = create :user
      @project = create :project
    end

    it { expect(User.not_in_project(@project)).to include(@user, @project.owner) }
  end

  describe 'user creation' do
    describe 'normal user' do
      let(:user) { create(:user, name: 'John Smith') }

      it { expect(user.is_admin?).to be_falsey }
      it { expect(user.require_ssh_key?).to be_truthy }
      it { expect(user.can_create_group?).to be_truthy }
      it { expect(user.can_create_project?).to be_truthy }
      it { expect(user.first_name).to eq('John') }
    end

    describe 'with defaults' do
      let(:user) { User.new }

      it "should apply defaults to user" do
        expect(user.projects_limit).to eq(Gitlab.config.gitlab.default_projects_limit)
        expect(user.can_create_group).to eq(Gitlab.config.gitlab.default_can_create_group)
        expect(user.theme_id).to eq(Gitlab.config.gitlab.default_theme)
      end
    end

    describe 'with default overrides' do
      let(:user) { User.new(projects_limit: 123, can_create_group: false, can_create_team: true, theme_id: 1) }

      it "should apply defaults to user" do
        expect(user.projects_limit).to eq(123)
        expect(user.can_create_group).to be_falsey
        expect(user.theme_id).to eq(1)
      end
    end
  end

  describe '.find_by_any_email' do
    it 'finds by primary email' do
      user = create(:user, email: 'foo@example.com')

      expect(User.find_by_any_email(user.email)).to eq user
    end

    it 'finds by secondary email' do
      email = create(:email, email: 'foo@example.com')
      user  = email.user

      expect(User.find_by_any_email(email.email)).to eq user
    end

    it 'returns nil when nothing found' do
      expect(User.find_by_any_email('')).to be_nil
    end
  end

  describe 'search' do
    let(:user1) { create(:user, username: 'James', email: 'james@testing.com') }
    let(:user2) { create(:user, username: 'jameson', email: 'jameson@example.com') }

    it "should be case insensitive" do
      expect(User.search(user1.username.upcase).to_a).to eq([user1])
      expect(User.search(user1.username.downcase).to_a).to eq([user1])
      expect(User.search(user2.username.upcase).to_a).to eq([user2])
      expect(User.search(user2.username.downcase).to_a).to eq([user2])
      expect(User.search(user1.username.downcase).to_a.count).to eq(2)
      expect(User.search(user2.username.downcase).to_a.count).to eq(1)
    end
  end

  describe 'by_username_or_id' do
    let(:user1) { create(:user, username: 'foo') }

    it "should get the correct user" do
      expect(User.by_username_or_id(user1.id)).to eq(user1)
      expect(User.by_username_or_id('foo')).to eq(user1)
      expect(User.by_username_or_id(-1)).to be_nil
      expect(User.by_username_or_id('bar')).to be_nil
    end
  end

  describe '.by_login' do
    let(:username) { 'John' }
    let!(:user) { create(:user, username: username) }

    it 'should get the correct user' do
      expect(User.by_login(user.email.upcase)).to eq user
      expect(User.by_login(user.email)).to eq user
      expect(User.by_login(username.downcase)).to eq user
      expect(User.by_login(username)).to eq user
      expect(User.by_login(nil)).to be_nil
      expect(User.by_login('')).to be_nil
    end
  end

  describe '.find_by_username!' do
    it 'raises RecordNotFound' do
      expect { described_class.find_by_username!('JohnDoe') }.
        to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'is case-insensitive' do
      user = create(:user, username: 'JohnDoe')
      expect(described_class.find_by_username!('JOHNDOE')).to eq user
    end
  end

  describe 'all_ssh_keys' do
    it { is_expected.to have_many(:keys).dependent(:destroy) }

    it "should have all ssh keys" do
      user = create :user
      key = create :key, key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD33bWLBxu48Sev9Fert1yzEO4WGcWglWF7K/AwblIUFselOt/QdOL9DSjpQGxLagO1s9wl53STIO8qGS4Ms0EJZyIXOEFMjFJ5xmjSy+S37By4sG7SsltQEHMxtbtFOaW5LV2wCrX+rUsRNqLMamZjgjcPO0/EgGCXIGMAYW4O7cwGZdXWYIhQ1Vwy+CsVMDdPkPgBXqK7nR/ey8KMs8ho5fMNgB5hBw/AL9fNGhRw3QTD6Q12Nkhl4VZES2EsZqlpNnJttnPdp847DUsT6yuLRlfiQfz5Cn9ysHFdXObMN5VYIiPFwHeYCZp1X2S4fDZooRE8uOLTfxWHPXwrhqSH", user_id: user.id

      expect(user.all_ssh_keys).to include(key.key)
    end
  end

  describe :avatar_type do
    let(:user) { create(:user) }

    it "should be true if avatar is image" do
      user.update_attribute(:avatar, 'uploads/avatar.png')
      expect(user.avatar_type).to be_truthy
    end

    it "should be false if avatar is html page" do
      user.update_attribute(:avatar, 'uploads/avatar.html')
      expect(user.avatar_type).to eq(["only images allowed"])
    end
  end

  describe :requires_ldap_check? do
    let(:user) { User.new }

    it 'is false when LDAP is disabled' do
      # Create a condition which would otherwise cause 'true' to be returned
      allow(user).to receive(:ldap_user?).and_return(true)
      user.last_credential_check_at = nil
      expect(user.requires_ldap_check?).to be_falsey
    end

    context 'when LDAP is enabled' do
      before do
        allow(Gitlab.config.ldap).to receive(:enabled).and_return(true)
      end

      it 'is false for non-LDAP users' do
        allow(user).to receive(:ldap_user?).and_return(false)
        expect(user.requires_ldap_check?).to be_falsey
      end

      context 'and when the user is an LDAP user' do
        before do
          allow(user).to receive(:ldap_user?).and_return(true)
        end

        it 'is true when the user has never had an LDAP check before' do
          user.last_credential_check_at = nil
          expect(user.requires_ldap_check?).to be_truthy
        end

        it 'is true when the last LDAP check happened over 1 hour ago' do
          user.last_credential_check_at = 2.hours.ago
          expect(user.requires_ldap_check?).to be_truthy
        end
      end
    end
  end

  describe :ldap_user? do
    it "is true if provider name starts with ldap" do
      user = create(:omniauth_user, provider: 'ldapmain')
      expect( user.ldap_user? ).to be_truthy
    end

    it "is false for other providers" do
      user = create(:omniauth_user, provider: 'other-provider')
      expect( user.ldap_user? ).to be_falsey
    end

    it "is false if no extern_uid is provided" do
      user = create(:omniauth_user, extern_uid: nil)
      expect( user.ldap_user? ).to be_falsey
    end
  end

  describe :ldap_identity do
    it "returns ldap identity" do
      user = create :omniauth_user
      expect(user.ldap_identity.provider).not_to be_empty
    end
  end

  describe '#full_website_url' do
    let(:user) { create(:user) }

    it 'begins with http if website url omits it' do
      user.website_url = 'test.com'

      expect(user.full_website_url).to eq 'http://test.com'
    end

    it 'begins with http if website url begins with http' do
      user.website_url = 'http://test.com'

      expect(user.full_website_url).to eq 'http://test.com'
    end

    it 'begins with https if website url begins with https' do
      user.website_url = 'https://test.com'

      expect(user.full_website_url).to eq 'https://test.com'
    end
  end

  describe '#short_website_url' do
    let(:user) { create(:user) }

    it 'does not begin with http if website url omits it' do
      user.website_url = 'test.com'

      expect(user.short_website_url).to eq 'test.com'
    end

    it 'does not begin with http if website url begins with http' do
      user.website_url = 'http://test.com'

      expect(user.short_website_url).to eq 'test.com'
    end

    it 'does not begin with https if website url begins with https' do
      user.website_url = 'https://test.com'

      expect(user.short_website_url).to eq 'test.com'
    end
  end

  describe "#starred?" do
    it "determines if user starred a project" do
      user = create :user
      project1 = create :project, :public
      project2 = create :project, :public

      expect(user.starred?(project1)).to be_falsey
      expect(user.starred?(project2)).to be_falsey

      star1 = UsersStarProject.create!(project: project1, user: user)
      expect(user.starred?(project1)).to be_truthy
      expect(user.starred?(project2)).to be_falsey

      star2 = UsersStarProject.create!(project: project2, user: user)
      expect(user.starred?(project1)).to be_truthy
      expect(user.starred?(project2)).to be_truthy

      star1.destroy
      expect(user.starred?(project1)).to be_falsey
      expect(user.starred?(project2)).to be_truthy

      star2.destroy
      expect(user.starred?(project1)).to be_falsey
      expect(user.starred?(project2)).to be_falsey
    end
  end

  describe "#toggle_star" do
    it "toggles stars" do
      user = create :user
      project = create :project, :public

      expect(user.starred?(project)).to be_falsey
      user.toggle_star(project)
      expect(user.starred?(project)).to be_truthy
      user.toggle_star(project)
      expect(user.starred?(project)).to be_falsey
    end
  end

  describe "#sort" do
    before do
      User.delete_all
      @user = create :user, created_at: Date.today, last_sign_in_at: Date.today, name: 'Alpha'
      @user1 = create :user, created_at: Date.today - 1, last_sign_in_at: Date.today - 1, name: 'Omega'
    end

    it "sorts users as recently_signed_in" do
      expect(User.sort('recent_sign_in').first).to eq(@user)
    end

    it "sorts users as late_signed_in" do
      expect(User.sort('oldest_sign_in').first).to eq(@user1)
    end

    it "sorts users as recently_created" do
      expect(User.sort('created_desc').first).to eq(@user)
    end

    it "sorts users as late_created" do
      expect(User.sort('created_asc').first).to eq(@user1)
    end

    it "sorts users by name when nil is passed" do
      expect(User.sort(nil).first).to eq(@user)
    end
  end

  describe "#contributed_projects_ids" do
    subject { create(:user) }
    let!(:project1) { create(:project) }
    let!(:project2) { create(:project, forked_from_project: project3) }
    let!(:project3) { create(:project) }
    let!(:merge_request) { create(:merge_request, source_project: project2, target_project: project3, author: subject) }
    let!(:push_event) { create(:event, action: Event::PUSHED, project: project1, target: project1, author: subject) }
    let!(:merge_event) { create(:event, action: Event::CREATED, project: project3, target: merge_request, author: subject) }

    before do
      project1.team << [subject, :master]
      project2.team << [subject, :master]
    end

    it "includes IDs for projects the user has pushed to" do
      expect(subject.contributed_projects_ids).to include(project1.id)
    end

    it "includes IDs for projects the user has had merge requests merged into" do
      expect(subject.contributed_projects_ids).to include(project3.id)
    end

    it "doesn't include IDs for unrelated projects" do
      expect(subject.contributed_projects_ids).not_to include(project2.id)
    end
  end

  describe :can_be_removed? do
    subject { create(:user) }

    context 'no owned groups' do
      it { expect(subject.can_be_removed?).to be_truthy }
    end

    context 'has owned groups' do
      before do
        group = create(:group)
        group.add_owner(subject)
      end

      it { expect(subject.can_be_removed?).to be_falsey }
    end
  end

  describe "#recent_push" do
    subject { create(:user) }
    let!(:project1) { create(:project) }
    let!(:project2) { create(:project, forked_from_project: project1) }
    let!(:push_data) { Gitlab::PushDataBuilder.build_sample(project2, subject) }
    let!(:push_event) { create(:event, action: Event::PUSHED, project: project2, target: project1, author: subject, data: push_data) }

    before do
      project1.team << [subject, :master]
      project2.team << [subject, :master]
    end

    it "includes push event" do
      expect(subject.recent_push).to eq(push_event)
    end

    it "excludes push event if branch has been deleted" do
      allow_any_instance_of(Repository).to receive(:branch_names).and_return(['foo'])

      expect(subject.recent_push).to eq(nil)
    end

    it "excludes push event if MR is opened for it" do
      create(:merge_request, source_project: project2, target_project: project1, source_branch: project2.default_branch, target_branch: 'fix', author: subject)

      expect(subject.recent_push).to eq(nil)
    end
  end
end
