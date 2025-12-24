# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/security_e2e_tests'

RSpec.describe Tooling::Danger::SecurityE2eTests, feature_category: :tooling do
  include_context 'with dangerfile'

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }

  subject(:security_e2e_tests) { fake_danger.new(helper: fake_helper) }

  describe '#check!' do
    context 'when not a security MR' do
      before do
        allow(fake_helper).to receive(:security_mr?).and_return(false)
      end

      it 'does not warn' do
        expect(security_e2e_tests).not_to receive(:warn)

        security_e2e_tests.check!
      end
    end

    context 'when a security MR' do
      before do
        allow(fake_helper).to receive(:security_mr?).and_return(true)
      end

      context 'when there are no qa/ changes' do
        before do
          allow(fake_helper).to receive(:all_changed_files).and_return(%w[app/models/user.rb spec/models/user_spec.rb])
        end

        it 'does not warn' do
          expect(security_e2e_tests).not_to receive(:warn)

          security_e2e_tests.check!
        end
      end

      context 'when there are only qa/ changes' do
        before do
          allow(fake_helper).to receive(:all_changed_files).and_return(%w[qa/specs/features/login_spec.rb])
        end

        it 'does not warn' do
          expect(security_e2e_tests).not_to receive(:warn)

          security_e2e_tests.check!
        end
      end

      context 'when there are only test changes (qa/, spec/, ee/spec/)' do
        before do
          allow(fake_helper).to receive(:all_changed_files)
            .and_return(%w[qa/specs/features/login_spec.rb spec/models/user_spec.rb ee/spec/models/project_spec.rb])
        end

        it 'does not warn' do
          expect(security_e2e_tests).not_to receive(:warn)

          security_e2e_tests.check!
        end
      end

      context 'when there are qa/ changes and non-test changes' do
        before do
          allow(fake_helper).to receive(:all_changed_files)
            .and_return(%w[qa/specs/features/login_spec.rb app/models/user.rb])
        end

        it 'warns about E2E test changes in security MR' do
          expect(security_e2e_tests).to receive(:warn).with(described_class::SECURITY_E2E_TEST_WARNING, sticky: false)

          security_e2e_tests.check!
        end
      end

      context 'when there are qa/ changes with spec/ and non-test changes' do
        before do
          allow(fake_helper).to receive(:all_changed_files)
            .and_return(%w[qa/specs/features/login_spec.rb spec/models/user_spec.rb lib/gitlab/auth.rb])
        end

        it 'warns about E2E test changes in security MR' do
          expect(security_e2e_tests).to receive(:warn).with(described_class::SECURITY_E2E_TEST_WARNING, sticky: false)

          security_e2e_tests.check!
        end
      end
    end
  end
end
