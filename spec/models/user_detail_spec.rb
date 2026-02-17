# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserDetail, feature_category: :system_access do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:bot_namespace).inverse_of(:bot_user_details) }

  describe 'validations' do
    context 'for onboarding_status json schema' do
      let(:step_url) { '_some_string_' }
      let(:email_opt_in) { true }
      let(:registration_type) { 'free' }
      let(:registration_objective) { 0 }
      let(:setup_for_company) { true }
      let(:glm_source) { 'glm_source' }
      let(:glm_content) { 'glm_content' }
      let(:joining_project) { true }
      let(:role) { 0 }
      let(:onboarding_status) do
        {
          step_url: step_url,
          email_opt_in: email_opt_in,
          initial_registration_type: registration_type,
          registration_type: registration_type,
          registration_objective: registration_objective,
          glm_source: glm_source,
          glm_content: glm_content,
          joining_project: joining_project,
          setup_for_company: setup_for_company,
          role: role
        }
      end

      it { is_expected.to allow_value(onboarding_status).for(:onboarding_status) }

      context 'for step_url' do
        let(:onboarding_status) do
          {
            step_url: step_url
          }
        end

        it { is_expected.to allow_value(onboarding_status).for(:onboarding_status) }

        context "when 'step_url' is invalid" do
          let(:step_url) { [] }

          it { is_expected.not_to allow_value(onboarding_status).for(:onboarding_status) }
        end
      end

      context 'for email_opt_in' do
        let(:onboarding_status) do
          {
            email_opt_in: email_opt_in
          }
        end

        it { is_expected.to allow_value(onboarding_status).for(:onboarding_status) }

        context "when 'email_opt_in' is invalid" do
          let(:email_opt_in) { 'true' }

          it { is_expected.not_to allow_value(onboarding_status).for(:onboarding_status) }
        end
      end

      context 'for initial_registration_type' do
        let(:onboarding_status) do
          {
            initial_registration_type: registration_type
          }
        end

        it { is_expected.to allow_value(onboarding_status).for(:onboarding_status) }

        context "when 'initial_registration_type' is invalid" do
          let(:registration_type) { [] }

          it { is_expected.not_to allow_value(onboarding_status).for(:onboarding_status) }
        end
      end

      context 'for registration_type' do
        let(:onboarding_status) do
          {
            registration_type: registration_type
          }
        end

        it { is_expected.to allow_value(onboarding_status).for(:onboarding_status) }

        context "when 'registration_type' is invalid" do
          let(:registration_type) { [] }

          it { is_expected.not_to allow_value(onboarding_status).for(:onboarding_status) }
        end
      end

      context 'for registration_objective' do
        let(:onboarding_status) do
          {
            registration_objective: registration_objective
          }
        end

        it { is_expected.to allow_value(onboarding_status).for(:onboarding_status) }

        context "when 'registration_objective' is invalid" do
          let(:registration_objective) { [] }

          it { is_expected.not_to allow_value(onboarding_status).for(:onboarding_status) }
        end

        context "when 'registration_objective' is invalid integer" do
          let(:registration_objective) { 10 }

          it { is_expected.not_to allow_value(onboarding_status).for(:onboarding_status) }
        end

        context "when 'registration_objective' is invalid string" do
          let(:registration_objective) { 'long-string-not-listed' }

          it { is_expected.not_to allow_value(onboarding_status).for(:onboarding_status) }
        end
      end

      context 'for glm_content' do
        let(:onboarding_status) do
          {
            glm_content: glm_content
          }
        end

        it { is_expected.to allow_value(onboarding_status).for(:onboarding_status) }

        context "when 'glm_content' is invalid" do
          let(:glm_content) { [] }

          it { is_expected.not_to allow_value(onboarding_status).for(:onboarding_status) }
        end
      end

      context 'for glm_source' do
        let(:onboarding_status) do
          {
            glm_source: glm_source
          }
        end

        it { is_expected.to allow_value(onboarding_status).for(:onboarding_status) }

        context "when 'glm_source' is invalid" do
          let(:glm_source) { [] }

          it { is_expected.not_to allow_value(onboarding_status).for(:onboarding_status) }
        end
      end

      context 'for joining_project' do
        let(:onboarding_status) do
          {
            joining_project: joining_project
          }
        end

        it { is_expected.to allow_value(onboarding_status).for(:onboarding_status) }

        context "when 'joining_project' is invalid" do
          let(:joining_project) { 'true' }

          it { is_expected.not_to allow_value(onboarding_status).for(:onboarding_status) }
        end
      end

      context 'for setup_for_company' do
        let(:onboarding_status) do
          {
            setup_for_company: setup_for_company
          }
        end

        it { is_expected.to allow_value(onboarding_status).for(:onboarding_status) }

        context "when 'setup_for_company' is invalid" do
          let(:setup_for_company) { 'true' }

          it { is_expected.not_to allow_value(onboarding_status).for(:onboarding_status) }
        end
      end

      context 'for role' do
        let(:onboarding_status) do
          {
            role: role
          }
        end

        it { is_expected.to allow_value(onboarding_status).for(:onboarding_status) }

        context "when 'role' is invalid" do
          let(:role) { 10 }

          it { is_expected.not_to allow_value(onboarding_status).for(:onboarding_status) }
        end
      end

      context 'when there is no data' do
        let(:onboarding_status) { {} }

        it { is_expected.to allow_value(onboarding_status).for(:onboarding_status) }
      end

      context 'when trying to store an unsupported key' do
        let(:onboarding_status) do
          {
            unsupported_key: '_some_value_'
          }
        end

        it { is_expected.not_to allow_value(onboarding_status).for(:onboarding_status) }
      end

      context 'when validating bot namespace user type' do
        let(:namespace) { create(:namespace) }

        context 'for a human user' do
          let(:user) { build(:user) }
          let(:user_detail) { build(:user_detail, user: user) }

          it 'does not allow bot namespace to be set' do
            user_detail.bot_namespace = namespace

            expect(user_detail).not_to be_valid
            expect(user_detail.errors).to contain_exactly _('Bot namespace must only be set for bot user types')
          end

          context 'when invalid bot_namespace is already set' do
            before do
              user_detail.save!
              user_detail.update_column(:bot_namespace_id, namespace.id)
            end

            it 'is valid' do
              expect(user_detail).to be_valid
            end

            it 'can be set back to nil' do
              user_detail.bot_namespace = nil

              expect(user_detail).to be_valid
            end
          end
        end

        context 'for a bot user' do
          let(:user) { build(:user, :project_bot) }
          let(:user_detail) { build(:user_detail, user: user) }

          it 'allows bot namespace to be set' do
            user_detail.bot_namespace = namespace

            expect(user_detail).to be_valid
          end
        end
      end
    end

    describe '#job_title' do
      it { is_expected.not_to validate_presence_of(:job_title) }
      it { is_expected.to validate_length_of(:job_title).is_at_most(200) }
    end

    describe '#pronouns' do
      it { is_expected.not_to validate_presence_of(:pronouns) }
      it { is_expected.to validate_length_of(:pronouns).is_at_most(50) }
    end

    describe '#pronunciation' do
      it { is_expected.not_to validate_presence_of(:pronunciation) }
      it { is_expected.to validate_length_of(:pronunciation).is_at_most(255) }
    end

    describe '#bio' do
      it { is_expected.to validate_length_of(:bio).is_at_most(255) }
    end

    describe '#linkedin' do
      it { is_expected.to validate_length_of(:linkedin).is_at_most(500) }
    end

    describe '#twitter' do
      it { is_expected.to validate_length_of(:twitter).is_at_most(500) }
    end

    describe '#discord' do
      let(:error_message) { _('must contain only a discord user ID.') }

      it { is_expected.to validate_length_of(:discord).is_at_most(500) }

      it { is_expected.to allow_value('1234567890123456789').for(:discord) }
      it { is_expected.not_to allow_value('123456789').for(:discord).with_message(error_message) }
    end

    describe '#bluesky' do
      let(:error_message) { _('must contain only a bluesky did:plc identifier.') }

      it { is_expected.to allow_value('did:plc:ewvi7nxzyoun6zhxrhs64oiz').for(:bluesky) }
      it { is_expected.not_to allow_value('a' * 33).for(:bluesky).with_message(error_message) }

      it do
        is_expected.not_to allow_value('did:plc:ewvi7nxzyoun6zhxrhs64OIZ').for(:bluesky).with_message(error_message)
      end

      it { is_expected.not_to allow_value('did:web:example.com').for(:bluesky).with_message(error_message) }
    end

    describe '#mastodon' do
      let(:error_message) { _('must contain only a mastodon handle.') }

      it { is_expected.to validate_length_of(:mastodon).is_at_most(500) }
      it { is_expected.to allow_value('@robin@example.com').for(:mastodon) }
      it { is_expected.not_to allow_value('@robin').for(:mastodon).with_message(error_message) }
    end

    describe '#orcid' do
      let(:error_message) { _('must contain only a valid ORCID.') }

      it { is_expected.to allow_value('1234-1234-1234-1234').for(:orcid) }
      it { is_expected.to allow_value('1234-1234-1234-123X').for(:orcid) }

      it { is_expected.not_to allow_value('1234-1234-1234-1234-1234').for(:orcid).with_message(error_message) }
      it { is_expected.not_to allow_value('1234-1234').for(:orcid).with_message(error_message) }
      it { is_expected.not_to allow_value('abcd-abcd-abcd-abcd').for(:orcid).with_message(error_message) }
      it { is_expected.not_to allow_value('1234-1234-1234-123Y').for(:orcid).with_message(error_message) }
    end

    describe '#location' do
      it { is_expected.to validate_length_of(:location).is_at_most(500) }
    end

    describe '#organization' do
      it { is_expected.to validate_length_of(:organization).is_at_most(500) }
    end

    describe '#website_url' do
      it { is_expected.to validate_length_of(:website_url).is_at_most(500) }

      it 'only validates the website_url if it is changed' do
        user_detail = create(:user).user_detail
        # `update_attribute` required to bypass current validations
        # Validations on `User#website_url` were added after
        # there was already data in the database and `UserDetail#website_url` is
        # derived from `User#website_url` so this reproduces the state of some of
        # our production data
        user_detail.update_attribute(:website_url, 'NotAUrl')

        expect(user_detail).to be_valid

        user_detail.website_url = 'AlsoNotAUrl'

        expect(user_detail).not_to be_valid
        expect(user_detail.errors.full_messages).to match_array(["Website url is not a valid URL"])
      end
    end

    it { is_expected.to validate_length_of(:email_otp).is_equal_to(64).allow_nil }

    it { is_expected.to validate_length_of(:email_otp_last_sent_to).is_at_most(511) }
  end

  describe '#save' do
    let(:user_detail) do
      attributes = {
        bio: 'bio',
        discord: '1234567890123456789',
        linkedin: 'linkedin',
        location: 'location',
        bluesky: 'did:plc:ewvi7nxzyoun6zhxrhs64oiz',
        orcid: '1234-1234-1234-1234',
        mastodon: '@robin@example.com',
        user_detail_organization: 'organization',
        twitter: 'twitter',
        website_url: 'https://example.com'
      }

      create(:user, attributes).user_detail
    end

    shared_examples 'prevents `nil` value' do |attr|
      it 'converts `nil` to the empty string' do
        user_detail[attr] = nil
        expect { user_detail.save! }
          .to change { user_detail[attr] }.to('')
          .and not_change { user_detail.attributes.except(attr.to_s) }
      end
    end

    it_behaves_like 'prevents `nil` value', :bio
    it_behaves_like 'prevents `nil` value', :discord
    it_behaves_like 'prevents `nil` value', :linkedin
    it_behaves_like 'prevents `nil` value', :location
    it_behaves_like 'prevents `nil` value', :bluesky
    it_behaves_like 'prevents `nil` value', :orcid
    it_behaves_like 'prevents `nil` value', :mastodon
    it_behaves_like 'prevents `nil` value', :organization
    it_behaves_like 'prevents `nil` value', :twitter
    it_behaves_like 'prevents `nil` value', :website_url
  end

  describe 'sanitization' do
    using RSpec::Parameterized::TableSyntax

    subject { build(:user_detail, field => input).tap(&:validate) }

    shared_examples 'standard sanitization tests' do
      # rubocop:disable Layout/LineLength -- Ignore long lines to keep single line table format
      where(:field, :input, :expected) do
        # HTML tags sanitization - all fields
        :bluesky      | '<a href="//evil.com">did:plc:ewvi7nxzyoun6zhxrhs64oiz<a>'   | 'did:plc:ewvi7nxzyoun6zhxrhs64oiz'
        :discord      | '<a href="//evil.com">1234567890987654321<a>'                | '1234567890987654321'
        :linkedin     | '<a href="//evil.com">https://example.com<a>'                | 'https://example.com'
        :mastodon     | '<a href="//evil.com">@robin@example.com<a>'                 | '@robin@example.com'
        :orcid        | '<a href="//evil.com">1234-1234-1234-1234<a>'                | '1234-1234-1234-1234'
        :twitter      | '<a href="//evil.com">https://example.com<a>'                | 'https://example.com'
        :website_url  | '<a href="//evil.com">https://example.com<a>'                | 'https://example.com'
        :github       | '<a href="//evil.com">https://example.com<a>'                | 'https://example.com'
        :location     | '<a href="//evil.com">https://example.com<a>'                | 'https://example.com'
        :organization | '<a href="//evil.com">https://example.com<a>'                | 'https://example.com'

        # iframe scripts sanitization
        :bluesky      | '<iframe src=javascript:alert()><iframe>'                    | ''
        :discord      | '<iframe src=javascript:alert()><iframe>'                    | ''
        :linkedin     | '<iframe src=javascript:alert()><iframe>'                    | ''
        :mastodon     | '<iframe src=javascript:alert()><iframe>'                    | ''
        :orcid        | '<iframe src=javascript:alert()>1234-1234-1234-1234<iframe>' | ''
        :twitter      | '<iframe src=javascript:alert()><iframe>'                    | ''
        :website_url  | '<iframe src=javascript:alert()><iframe>'                    | ''
        :github       | '<iframe src=javascript:alert()><iframe>'                    | ''
        :location     | '<iframe src=javascript:alert()><iframe>'                    | ''
        :organization | '<iframe src=javascript:alert()><iframe>'                    | ''

        # js scripts sanitization
        :bluesky      | '<script>alert("Test")</script>'                             | ''
        :discord      | '<script>alert("Test")</script>'                             | ''
        :linkedin     | '<script>alert("Test")</script>'                             | ''
        :mastodon     | '<script>alert("Test")</script>'                             | ''
        :orcid        | '<script>alert("Test")1234-1234-1234-1234</script>'          | ''
        :twitter      | '<script>alert("Test")</script>'                             | ''
        :website_url  | '<script>alert("Test")</script>'                             | ''
        :github       | '<script>alert("Test")</script>'                             | ''
        :location     | '<script>alert("Test")</script>'                             | ''
        :organization | '<script>alert("Test")</script>'                             | ''
      end
      # rubocop:enable Layout/LineLength

      with_them do
        it { is_expected.to be_valid }
        it { is_expected.to have_attributes field => expected }
      end
    end

    it_behaves_like 'standard sanitization tests'

    context 'with valid field inputs' do
      where(:field, :input, :expected) do
        # HTML entities NOT encoding - fields that encode & to &amp;
        :linkedin     | 'test&attr'                                  | 'test&attr'
        :twitter      | 'test&attr'                                  | 'test&attr'
        :website_url  | 'http://example.com?test&attr'               | 'http://example.com?test&attr'
        :github       | 'test&attr'                                  | 'test&attr'

        # HTML entities NOT encoded - location, organization preserve &
        :location     | 'test&attr'                                  | 'test&attr'
        :organization | 'test&attr'                                  | 'test&attr'

        # Legitimate edge cases
        :website_url  | 'https://example.com/search?q=hello%20world' | 'https://example.com/search?q=hello%20world'
        :twitter      | 'https://twitter.com/user'                   | 'https://twitter.com/user'
        :linkedin     | 'https://linkedin.com/in/user-name'          | 'https://linkedin.com/in/user-name'
        :twitter      | '@user_name'                                 | '@user_name'
        :discord      | '123456789012345678'                         | '123456789012345678'
        :website_url  | 'https://example.com?foo=bar&baz=qux'        | 'https://example.com?foo=bar&baz=qux'
        :github       | 'https://github.com/user/repo'               | 'https://github.com/user/repo'
        :website_url  | 'https://example.com/path/to/page'           | 'https://example.com/path/to/page'
      end

      with_them do
        it { is_expected.to be_valid }
        it { is_expected.to have_attributes field => expected }
      end
    end

    context 'with invalid field inputs' do
      where(:field, :input, :error_message) do
        :bluesky     | '&lt;script&gt;alert(1)&lt;/script&gt;'   | 'cannot contain escaped HTML entities'
        :discord     | '&lt;script&gt;alert(1)&lt;/script&gt;'   | 'cannot contain escaped HTML entities'
        :linkedin    | '&lt;script&gt;alert(1)&lt;/script&gt;'   | 'cannot contain escaped HTML entities'
        :mastodon    | '&lt;script&gt;alert(1)&lt;/script&gt;'   | 'cannot contain escaped HTML entities'
        :orcid       | '&lt;script&gt;alert(1)&lt;/script&gt;'   | 'cannot contain escaped HTML entities'
        :twitter     | '&lt;script&gt;alert(1)&lt;/script&gt;'   | 'cannot contain escaped HTML entities'
        :website_url | '&lt;script&gt;alert(1)&lt;/script&gt;'   | 'cannot contain escaped HTML entities'
        :github      | '&lt;script&gt;alert(1)&lt;/script&gt;'   | 'cannot contain escaped HTML entities'

        :bluesky     | '%2526lt%253Bscript%2526gt%253B'          | 'cannot contain escaped components'
        :discord     | '%2526lt%253Bscript%2526gt%253B'          | 'cannot contain escaped components'
        :linkedin    | '%2526lt%253Bscript%2526gt%253B'          | 'cannot contain escaped components'
        :mastodon    | '%2526lt%253Bscript%2526gt%253B'          | 'cannot contain escaped components'
        :orcid       | '%2526lt%253Bscript%2526gt%253B'          | 'cannot contain escaped components'
        :twitter     | '%2526lt%253Bscript%2526gt%253B'          | 'cannot contain escaped components'
        :website_url | '%2526lt%253Bscript%2526gt%253B'          | 'cannot contain escaped components'
        :github      | '%2526lt%253Bscript%2526gt%253B'          | 'cannot contain escaped components'

        :bluesky     | 'main../../../../../../api/v4/projects/1' | 'cannot contain a path traversal component'
        :discord     | 'main../../../../../../api/v4/projects/1' | 'cannot contain a path traversal component'
        :linkedin    | 'main../../../../../../api/v4/projects/1' | 'cannot contain a path traversal component'
        :mastodon    | 'main../../../../../../api/v4/projects/1' | 'cannot contain a path traversal component'
        :orcid       | 'main../../../../../../api/v4/projects/1' | 'cannot contain a path traversal component'
        :twitter     | 'main../../../../../../api/v4/projects/1' | 'cannot contain a path traversal component'
        :website_url | 'main../../../../../../api/v4/projects/1' | 'cannot contain a path traversal component'
        :github      | 'main../../../../../../api/v4/projects/1' | 'cannot contain a path traversal component'
      end

      with_them do
        it { is_expected.not_to be_valid }
        it { is_expected.to have_attributes errors: hash_including(field => array_including(error_message)) }
      end
    end

    context 'when feature flag :validate_sanitizable_user_details is disabled' do
      before do
        stub_feature_flags(validate_sanitizable_user_details: false)
      end

      it_behaves_like 'standard sanitization tests'

      where(:field, :input, :expected) do
        # HTML entities encoding - fields that encode & to &amp;
        :linkedin     | 'test&attr'                                 | 'test&amp;attr'
        :twitter      | 'test&attr'                                 | 'test&amp;attr'
        :github       | 'test&attr'                                 | 'test&amp;attr'

        # HTML entities NOT encoded - location, organization, website_url preserve &
        :location     | 'test&attr'                                 | 'test&attr'
        :organization | 'test&attr'                                 | 'test&attr'
        :website_url  | 'http://example.com?test&attr'              | 'http://example.com?test&attr'

        # Does not apply Sanitizable validations
        :twitter      | '&lt;script&gt;alert(1)&lt;/script&gt;'     | '&lt;script&gt;alert(1)&lt;/script&gt;'
        :linkedin     | '%2526lt%253Bscript%2526gt%253B'            | '%2526lt%253Bscript%2526gt%253B'
        :github       | 'main../../../../../../api/v4/projects/1'   | 'main../../../../../../api/v4/projects/1'
      end

      with_them do
        it { is_expected.to be_valid }
        it { is_expected.to have_attributes field => expected }
      end
    end
  end

  describe '#email_otp' do
    let(:user_detail) { build(:user_detail) }
    let(:hashed_value) { Devise.token_generator.digest(User, generate(:email), '123456') }

    it 'can be set to a hashed value' do
      expect { user_detail.email_otp = hashed_value }
        .to change { user_detail.email_otp }.to(hashed_value)
    end
  end

  describe '#as_json' do
    let(:user_detail) { build(:user_detail, email_otp: Digest::SHA2.hexdigest('')) }

    it 'includes attributes' do
      expect(user_detail.as_json.keys).not_to be_empty
    end

    it 'does not include email_otp' do
      expect(user_detail.as_json).not_to have_key('email_otp')
    end
  end
end
