# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::ExternalUsernameSanitizer, feature_category: :system_access do
  subject(:sanitized_name) { described_class.new(external_username).sanitize }

  describe '#sanitize' do
    using RSpec::Parameterized::TableSyntax

    where(:external_username, :output) do
      'alice'                         | 'alice'
      'admin'                         | 'admin1'
      'testy.git'                     | 'testy'
      '___carly_the_capybara'         | 'carly_the_capybara'
      'shingo___the...shiba---inu'    | 'shingo_the.shiba-inu'
      'francis-the-ferret-'           | 'francis-the-ferret'
      '___opie.-_!the$_#^^opossum---' | 'opie.the_opossum'
      ' --ricky.^#!__the._raccoon--'  | 'ricky.the.raccoon'
      '*&$amy_the_armadillo'          | 'amy_the_armadillo'
      'bobby-the-badger$!()'          | 'bobby-the-badger'
      'denise^&*the!dhole'            | 'denisethedhole'
    end

    with_them do
      it { is_expected.to eq(output) }
    end
  end

  context 'when external username is a ReDoS pattern' do
    let(:external_username) { "#{'-' * 54773}\x00-z" }

    it { is_expected.to eq('z') }
  end

  context 'with existing users' do
    let!(:user_capybara) { create(:user, :with_namespace, username: 'carly_the_capybara') }
    let(:external_username) { '___carly_the_capybara' }

    it { is_expected.to eq('carly_the_capybara1') }
  end
end
