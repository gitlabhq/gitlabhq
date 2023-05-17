# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::UpdateCanonicalEmailService, feature_category: :user_profile do
  let(:other_email) { "differentaddress@includeddomain.com" }

  before do
    stub_const("Users::UpdateCanonicalEmailService::INCLUDED_DOMAINS_PATTERN", [/includeddomain/])
  end

  describe '#initialize' do
    context 'unsuccessful' do
      it 'raises an error if there is no user' do
        expect { described_class.new(user: nil) }.to raise_error(ArgumentError, /Please provide a user/)
      end

      it 'raises an error if the object is not a User' do
        expect { described_class.new(user: 123) }.to raise_error(ArgumentError, /Please provide a user/)
      end
    end

    context 'when a user is provided' do
      it 'does not error' do
        user = build(:user)

        expect { described_class.new(user: user) }.not_to raise_error
      end
    end
  end

  describe "#canonicalize_email" do
    let(:user) { build(:user) }
    let(:subject) { described_class.new(user: user) }

    context 'when the email domain is included' do
      context 'strips out any . or anything after + in the agent for included domains' do
        using RSpec::Parameterized::TableSyntax

        let(:expected_result) { 'user@includeddomain.com' }

        where(:raw_email, :expected_result) do
          'user@includeddomain.com'      | 'user@includeddomain.com'
          'u.s.e.r@includeddomain.com'   | 'user@includeddomain.com'
          'user+123@includeddomain.com'  | 'user@includeddomain.com'
          'us.er+123@includeddomain.com' | 'user@includeddomain.com'
        end

        with_them do
          before do
            user.email = raw_email
          end

          specify do
            subject.execute

            expect(user.user_canonical_email).not_to be_nil
            expect(user.user_canonical_email.canonical_email).to eq expected_result
          end
        end
      end

      context 'when the user has an existing canonical email' do
        it 'updates the user canonical email record' do
          user.user_canonical_email = build(:user_canonical_email, canonical_email: other_email)
          user.email = "us.er+123@includeddomain.com"

          subject.execute

          expect(user.user_canonical_email.canonical_email).to eq "user@includeddomain.com"
        end
      end
    end

    context 'when the email domain is not included' do
      it 'returns nil' do
        user.email = "u.s.er+343@excludeddomain.com"

        subject.execute

        expect(user.user_canonical_email).to be_nil
      end

      it 'destroys any existing UserCanonicalEmail record' do
        user.email = "u.s.er+343@excludeddomain.com"
        user.user_canonical_email = build(:user_canonical_email, canonical_email: other_email)
        expect(user.user_canonical_email).to receive(:delete)

        subject.execute
      end
    end

    context 'when the user email is not processable' do
      [nil, 'nonsense'].each do |invalid_address|
        context "with #{invalid_address}" do
          before do
            user.email = invalid_address
          end

          specify do
            subject.execute

            expect(user.user_canonical_email).to be_nil
          end

          it 'preserves any existing record' do
            user.email = nil
            user.user_canonical_email = build(:user_canonical_email, canonical_email: other_email)

            subject.execute

            expect(user.user_canonical_email.canonical_email).to eq other_email
          end
        end
      end
    end
  end
end
