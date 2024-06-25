# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::WeakPasswords, feature_category: :system_access do
  describe "#weak_for_user?" do
    using RSpec::Parameterized::TableSyntax

    let(:user) do
      build_stubbed(:user, username: "56d4ab689a_win",
        name: "Weakést McWeaky-Pass Jr",
        email: "predictāble.ZZZ+seventeen@examplecorp.com",
        public_email: "fortunate@acme.com"
      )
    end

    where(:password, :too_weak) do
      # A random password is not too weak
      "d2262d56" | false

      # The case-insensitive weak password list
      "password" | true
      "pAssWord" | true
      "princeofdarkness" | true

      # Forbidden substrings
      "A1B2gitlabC3"          | true
      "gitlab123"             | true
      "theonedevopsplatform"  | true
      "A1gitlib"              | false

      # Predicatable name substrings
      "Aweakést"  | true
      "!@mCwEaKy" | true
      "A1B2pass"  | true
      "A1B2C3jr"  | false # jr is too short
      "3e18a7f60a908e329958396d68131d39e1b66a03ea420725e2a0fce7cb17pass" | false # Password is >= 64 chars

      # Predictable username substrings
      "56d4ab689a"      | true
      "56d4ab689a_win"  | true
      "56d4ab68"        | false # it's part of the username, but not a full part
      "A1B2Cwin"        | false # win is too short

      # Predictable user.email substrings
      "predictāble.ZZZ+seventeen@examplecorp.com" | true
      "predictable.ZZZ+seventeen@examplecorp.com" | true
      "predictāble.ZZZ+seventeen"                 | true
      "examplecorp.com"     | true
      "!@exAmplecorp"       | true
      "predictāble123"      | true
      "seventeen"           | true
      "predictable"         | false # the accent is different
      "A1B2CZzZ"            | false # ZZZ is too short
      # Other emails are not considered
      "fortunate@acme.com"  | false
      "A1B2acme"            | false
      "fortunate"           | false

      # A short password is not automatically too weak
      # We rely on User's password length validation, not WeakPasswords.
      "1"       | false
      "1234567" | false
      # But a short password with forbidden words or user attributes
      # is still weak
      "gitlab"  | true
      "pass"    | true
    end

    with_them do
      it { expect(subject.weak_for_user?(password, user)).to eq(too_weak) }
    end

    context 'with a user who has short email parts' do
      before do
        user.email = 'sid@1.io'
      end

      where(:password, :too_weak) do
        "11111111"    | true # This is on the weak password list
        "1.ioABCD"    | true # 1.io is long enough to match
        "sid@1.io"    | true # matches the email in full
        "sid@1.ioAB"  | true
        # sid, 1, and io on their own are too short
        "sid1ioAB"    | false
        "sidsidsi"    | false
        "ioioioio"    | false
      end

      with_them do
        it { expect(subject.weak_for_user?(password, user)).to eq(too_weak) }
      end
    end

    context 'with a user who is missing attributes' do
      before do
        user.name = nil
        user.email = nil
        user.username = nil
      end

      where(:password, :too_weak) do
        "d2262d56"  | false
        "password"  | true
        "gitlab123" | true
      end

      with_them do
        it { expect(subject.weak_for_user?(password, user)).to eq(too_weak) }
      end
    end
  end
end
