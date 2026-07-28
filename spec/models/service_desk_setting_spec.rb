# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ServiceDeskSetting, feature_category: :service_desk do
  subject(:setting) { build(:service_desk_setting) }

  it_behaves_like 'cells claimable model',
    subject_type: Cells::Claimable::CLAIMS_SUBJECT_TYPE::PROJECT,
    subject_key: :project_id,
    source_type: Cells::Claimable::CLAIMS_SOURCE_TYPE::RAILS_TABLE_SERVICE_DESK_SETTINGS,
    claiming_attributes: [:custom_email, :project_key_address_slug]

  describe '#handle_grpc_error' do
    context 'when error is ALREADY_EXISTS' do
      let(:grpc_error) { GRPC::AlreadyExists.new('conflict') }

      it 'assigns attribute-specific message' do
        setting.handle_grpc_error(grpc_error)

        expect(setting.errors[:base])
          .to include('custom_email or project_key_address_slug has already been taken')
      end
    end
  end

  describe '.cells_claims_scope' do
    let!(:with_email) { create(:service_desk_setting, custom_email: 'support@example.com') }
    let!(:with_project_key) { create(:service_desk_setting, project_key: 'key1') }
    let!(:without_claimable_attributes) { create(:service_desk_setting, custom_email: nil, project_key: nil) }

    it 'returns only settings with a non-nil custom_email or project_key_address_slug' do
      scope = described_class.cells_claims_scope

      expect(scope).to include(with_email, with_project_key)
      expect(scope).not_to include(without_claimable_attributes)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project_id) }
    it { is_expected.to validate_length_of(:outgoing_name).is_at_most(255) }
    it { is_expected.to validate_length_of(:project_key).is_at_most(255) }
    it { is_expected.to allow_value('abc123_').for(:project_key) }
    it { is_expected.not_to allow_value('abc 12').for(:project_key).with_message("can contain only lowercase letters, digits, and '_'.") }
    it { is_expected.not_to allow_value('Big val').for(:project_key) }
    it { is_expected.to validate_length_of(:custom_email).is_at_most(255) }

    describe '#custom_email_enabled' do
      it { expect(setting.custom_email_enabled).to be_falsey }
      it { expect(described_class.new(custom_email_enabled: true).custom_email_enabled).to be_truthy }

      context 'when set to true' do
        let(:expected_error_part) { 'cannot be enabled until verification process has finished.' }

        before do
          setting.custom_email = 'user@example.com'
          setting.custom_email_enabled = true
        end

        it 'is not valid' do
          is_expected.not_to be_valid
          expect(setting.errors[:custom_email_enabled].join).to include(expected_error_part)
        end

        context 'when custom email records exist' do
          let_it_be(:project) { create(:project) }
          let_it_be(:credential) { build(:service_desk_custom_email_credential, project: project).save!(validate: false) }

          let!(:verification) { create(:service_desk_custom_email_verification, project: project) }

          subject(:setting) { build_stubbed(:service_desk_setting, project: project) }

          before do
            project.reset
          end

          context 'when custom email verification started' do
            it 'is not valid' do
              is_expected.not_to be_valid
              expect(setting.errors[:custom_email_enabled].join).to include(expected_error_part)
            end
          end

          context 'when custom email verification has been finished' do
            before do
              verification.mark_as_finished!
            end

            it { is_expected.to be_valid }
          end
        end
      end
    end

    context 'when custom_email_enabled is true' do
      before do
        # Test without ServiceDesk::CustomEmailVerification for simplicity
        setting.custom_email_enabled = true
      end

      it { is_expected.to validate_presence_of(:custom_email) }
      it { is_expected.to validate_uniqueness_of(:custom_email).allow_nil }
      it { is_expected.to allow_value('support@example.com').for(:custom_email) }
      it { is_expected.to allow_value('support@xn--brggen-4ya.de').for(:custom_email) } # converted domain name with umlaut
      it { is_expected.to allow_value('support1@shop.example.com').for(:custom_email) }
      it { is_expected.to allow_value('support-shop_with.crazy-address@shop.example.com').for(:custom_email) }
      it { is_expected.not_to allow_value('support@example@example.com').for(:custom_email) }
      it { is_expected.not_to allow_value('support.example.com').for(:custom_email) }
      it { is_expected.not_to allow_value('example.com').for(:custom_email) }
      it { is_expected.not_to allow_value('example').for(:custom_email) }
      it { is_expected.not_to allow_value('" "@example.org').for(:custom_email) }
      it { is_expected.not_to allow_value('support+12@example.com').for(:custom_email) }
      it { is_expected.not_to allow_value('user@[IPv6:2001:db8::1]').for(:custom_email) }
      it { is_expected.not_to allow_value('"><script>alert(1);</script>"@example.org').for(:custom_email) }
      it { is_expected.not_to allow_value('file://example').for(:custom_email) }
      it { is_expected.not_to allow_value('no email at all').for(:custom_email) }
    end

    describe '#valid_issue_template' do
      let_it_be(:project) { create(:project, :custom_repo, files: { '.gitlab/issue_templates/service_desk.md' => 'template' }) }

      it 'is not valid if template does not exist' do
        settings = build(:service_desk_setting, project: project, issue_template_key: 'invalid key')

        expect(settings).not_to be_valid
        expect(settings.errors[:issue_template_key].first).to eq('is empty or does not exist')
      end

      it 'is valid if template exists' do
        settings = build(:service_desk_setting, project: project, issue_template_key: 'service_desk')

        expect(settings).to be_valid
      end
    end
  end

  describe '#custom_email_address_for_verification' do
    it 'returns nil' do
      expect(setting.custom_email_address_for_verification).to be_nil
    end

    context 'when custom_email exists' do
      it 'returns correct verification address' do
        setting.custom_email = 'support@example.com'
        expect(setting.custom_email_address_for_verification).to eq('support+verify@example.com')
      end
    end
  end

  describe '#valid_project_key' do
    # Creates two projects with same full path slug
    # group1/test/one and group1/test-one will both have 'group-test-one' slug
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group, name: 'test') }
    let_it_be(:project1) { create(:project, path: 'test-one', group: group) }
    let_it_be(:project2) { create(:project, path: 'one', group: subgroup) }
    let_it_be(:project_key) { 'key' }
    let!(:setting) do
      create(:service_desk_setting, project: project1, project_key: project_key)
    end

    context 'when project_key exists' do
      it 'is valid' do
        expect(setting).to be_valid
      end
    end

    context 'when project_key is unique for every project slug' do
      it 'does not add error' do
        settings = build(:service_desk_setting, project: project2, project_key: 'otherkey')

        expect(settings).to be_valid
      end
    end

    context 'when project with same slug and settings project_key exists' do
      it 'adds error' do
        settings = build(:service_desk_setting, project: project2, project_key: project_key)

        expect(settings).to be_invalid
        expect(settings.errors[:project_key].first).to eq('already in use for another service desk address.')
      end
    end
  end

  describe '#project_key_address_slug_conflict?' do
    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group, name: 'test') }
    let_it_be(:project1) { create(:project, path: 'test-one', group: group) }
    let_it_be(:project2) { create(:project, path: 'one', group: subgroup) }

    before do
      create(:service_desk_setting, project: project1, project_key: 'key')
    end

    it 'is true when another project shares the same slug and key' do
      setting = build(:service_desk_setting, project: project2, project_key: 'key')

      expect(setting.project_key_address_slug_conflict?).to be(true)
    end

    it 'is false when the key is unique for the slug' do
      setting = build(:service_desk_setting, project: project2, project_key: 'otherkey')

      expect(setting.project_key_address_slug_conflict?).to be(false)
    end

    it 'is false when no project_key is set' do
      setting = build(:service_desk_setting, project: project2, project_key: nil)

      expect(setting.project_key_address_slug_conflict?).to be(false)
    end
  end

  describe '#refresh_project_key_address_slug!' do
    let_it_be_with_reload(:project) { create(:project) }

    it 'recomputes and persists the slug from the current full path' do
      setting = create(:service_desk_setting, project: project, project_key: 'mykey')
      project.update!(path: 'renamed-project')

      setting.refresh_project_key_address_slug!

      expect(setting.reload.project_key_address_slug).to eq("#{project.reload.full_path_slug}-mykey")
    end

    it 'does nothing when there is no project_key' do
      setting = create(:service_desk_setting, project: project, project_key: nil)

      expect(setting).not_to receive(:save!)

      setting.refresh_project_key_address_slug!
    end
  end

  describe '#set_project_key_address_slug' do
    let_it_be_with_reload(:project) { create(:project) }

    let(:setting) { build(:service_desk_setting, project: project, project_key: project_key) }

    context 'when project_key is present' do
      let(:project_key) { 'mykey' }

      it 'stores the composite slug and project_key on save' do
        setting.save!

        expect(setting.project_key_address_slug).to eq("#{project.full_path_slug}-mykey")
      end

      it 'recomputes the value when the project path changes' do
        setting.save!

        project.update!(path: 'renamed-project')
        setting.save!

        expect(setting.project_key_address_slug).to eq("#{project.reload.full_path_slug}-mykey")
      end

      it 'recomputes the value on save even when the setting has no dirty attributes' do
        setting.save!
        setting.update_column(:project_key_address_slug, 'stale-value')
        setting.reload

        expect(setting.changed?).to be(false)
        expect { setting.save! }
          .to change { setting.project_key_address_slug }
          .from('stale-value')
          .to("#{project.full_path_slug}-mykey")
      end

      it 'clears the value when the project_key is removed' do
        setting.save!

        setting.update!(project_key: nil)

        expect(setting.project_key_address_slug).to be_nil
      end
    end

    context 'when project_key is blank' do
      let(:project_key) { nil }

      it 'leaves the value nil' do
        setting.save!

        expect(setting.project_key_address_slug).to be_nil
      end
    end
  end

  describe '#tickets_confidential_by_default?' do
    using RSpec::Parameterized::TableSyntax

    where(:visibility_level, :setting_value, :expected_value) do
      Gitlab::VisibilityLevel::PUBLIC  | true  | true
      Gitlab::VisibilityLevel::PUBLIC  | false | true
      Gitlab::VisibilityLevel::PRIVATE | true  | true
      Gitlab::VisibilityLevel::PRIVATE | false | false
    end

    with_them do
      let(:project) { build(:project, visibility_level: visibility_level) }

      subject(:setting) do
        build(:service_desk_setting, project: project, tickets_confidential_by_default: setting_value)
          .tickets_confidential_by_default?
      end

      it { is_expected.to be expected_value }
    end
  end

  describe 'associations' do
    let(:project) { build(:project) }
    let(:verification) { build(:service_desk_custom_email_verification) }
    let(:custom_email_settings) do
      build_stubbed(
        :service_desk_setting,
        custom_email: 'support@example.com'
      )
    end

    it { is_expected.to belong_to(:project) }

    it 'can access custom email verification from project' do
      project.service_desk_custom_email_verification = verification
      custom_email_settings.project = project

      expect(custom_email_settings.custom_email_verification).to eq(verification)
    end
  end
end
