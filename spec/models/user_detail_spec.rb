# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UserDetail do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to define_enum_for(:registration_objective).with_values([:basics, :move_repository, :code_storage, :exploring, :ci, :other, :joining_team]).with_suffix }

  describe 'validations' do
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

    describe '#skype' do
      it { is_expected.to validate_length_of(:skype).is_at_most(500) }
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
        user_detail = create(:user_detail)
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
  end

  describe '.user_fields_changed?' do
    let(:user) { create(:user) }

    context 'when user detail fields unchanged' do
      it 'returns false' do
        expect(described_class.user_fields_changed?(user)).to be false
      end

      %i[linkedin location organization skype twitter website_url].each do |attr|
        context "when #{attr} is changed" do
          before do
            user[attr] = 'new value'
          end

          it 'returns true' do
            expect(described_class.user_fields_changed?(user)).to be true
          end
        end
      end
    end
  end

  describe '#sanitize_attrs' do
    shared_examples 'sanitizes html' do |attr|
      it 'sanitizes html tags' do
        details = build_stubbed(:user_detail, attr => '<a href="//evil.com">https://example.com<a>')
        expect { details.sanitize_attrs }.to change { details[attr] }.to('https://example.com')
      end

      it 'sanitizes iframe scripts' do
        details = build_stubbed(:user_detail, attr => '<iframe src=javascript:alert()><iframe>')
        expect { details.sanitize_attrs }.to change { details[attr] }.to('')
      end

      it 'sanitizes js scripts' do
        details = build_stubbed(:user_detail, attr => '<script>alert("Test")</script>')
        expect { details.sanitize_attrs }.to change { details[attr] }.to('')
      end
    end

    %i[linkedin skype twitter website_url].each do |attr|
      it_behaves_like 'sanitizes html', attr

      it 'encodes HTML entities' do
        details = build_stubbed(:user_detail, attr => 'test&attr')
        expect { details.sanitize_attrs }.to change { details[attr] }.to('test&amp;attr')
      end
    end

    %i[location organization].each do |attr|
      it_behaves_like 'sanitizes html', attr

      it 'does not encode HTML entities' do
        details = build_stubbed(:user_detail, attr => 'test&attr')
        expect { details.sanitize_attrs }.not_to change { details[attr] }
      end
    end

    it 'sanitizes on validation' do
      details = build(:user_detail)

      expect(details)
        .to receive(:sanitize_attrs)
        .at_least(:once)
        .and_call_original

      details.save!
    end
  end

  describe '#assign_changed_fields_from_user' do
    let(:user_detail) { build(:user_detail) }

    shared_examples 'syncs field with `user_details`' do |field|
      it 'does not sync the field to `user_details` if unchanged' do
        expect { user_detail.assign_changed_fields_from_user }
          .to not_change { user_detail.public_send(field) }
      end

      it 'syncs the field to `user_details` if changed' do
        user_detail.user[field] = "new_value"
        expect { user_detail.assign_changed_fields_from_user }
          .to change { user_detail.public_send(field) }
          .to("new_value")
      end

      it 'truncates the field if too long' do
        user_detail.user[field] = 'a' * (UserDetail::DEFAULT_FIELD_LENGTH + 1)
        expect { user_detail.assign_changed_fields_from_user }
          .to change { user_detail.public_send(field) }
          .to('a' * UserDetail::DEFAULT_FIELD_LENGTH)
      end

      it 'properly syncs nil field to `user_details' do
        user_detail.user[field] = 'Test'
        user_detail.user.save!(validate: false)
        user_detail.user[field] = nil
        expect { user_detail.assign_changed_fields_from_user }
          .to change { user_detail.public_send(field) }
          .to('')
      end
    end

    it_behaves_like 'syncs field with `user_details`', :linkedin
    it_behaves_like 'syncs field with `user_details`', :location
    it_behaves_like 'syncs field with `user_details`', :organization
    it_behaves_like 'syncs field with `user_details`', :skype
    it_behaves_like 'syncs field with `user_details`', :twitter
    it_behaves_like 'syncs field with `user_details`', :website_url
  end
end
