# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ConfigChecker::ExternalDatabaseChecker do
  describe '#check' do
    subject { described_class.check }

    let_it_be(:deprecation_warning) { "Please upgrade" }
    let_it_be(:upcoming_deprecation_warning) { "Please consider upgrading" }

    context 'when database meets minimum version and there is no upcoming deprecation' do
      before do
        allow(Gitlab::Database).to receive(:postgresql_minimum_supported_version?).and_return(true)
        allow(Gitlab::Database).to receive(:postgresql_upcoming_deprecation?).and_return(false)
      end

      it { is_expected.to be_empty }
    end

    context 'when database does not meet minimum version and there is no upcoming deprecation' do
      before do
        allow(Gitlab::Database).to receive(:postgresql_minimum_supported_version?).and_return(false)
        allow(Gitlab::Database).to receive(:postgresql_upcoming_deprecation?).and_return(false)
      end

      it 'only returns notice about deprecated database version' do
        is_expected.to include(a_hash_including(message: include(deprecation_warning)))
        is_expected.not_to include(a_hash_including(message: include(upcoming_deprecation_warning)))
      end
    end

    context 'when database meets minimum version and there is an upcoming deprecation' do
      before do
        allow(Gitlab::Database).to receive(:postgresql_minimum_supported_version?).and_return(true)
        allow(Gitlab::Database).to receive(:postgresql_upcoming_deprecation?).and_return(true)
      end

      context 'inside the deprecation notice window' do
        before do
          allow(Gitlab::Database).to receive(:within_deprecation_notice_window?).and_return(true)
        end

        it 'only returns notice about an upcoming deprecation' do
          is_expected.to include(a_hash_including(message: include(upcoming_deprecation_warning)))
          is_expected.not_to include(a_hash_including(message: include(deprecation_warning)))
        end
      end

      context 'outside the deprecation notice window' do
        before do
          allow(Gitlab::Database).to receive(:within_deprecation_notice_window?).and_return(false)
        end

        it { is_expected.to be_empty }
      end
    end

    context 'when database does not meet minimum version and there is an upcoming deprecation' do
      before do
        allow(Gitlab::Database).to receive(:postgresql_minimum_supported_version?).and_return(false)
        allow(Gitlab::Database).to receive(:postgresql_upcoming_deprecation?).and_return(true)
      end

      context 'inside the deprecation notice window' do
        before do
          allow(Gitlab::Database).to receive(:within_deprecation_notice_window?).and_return(true)
        end

        it 'returns notice about deprecated database version and an upcoming deprecation' do
          is_expected.to include(
            a_hash_including(message: include(deprecation_warning)),
            a_hash_including(message: include(upcoming_deprecation_warning))
          )
        end
      end

      context 'outside the deprecation notice window' do
        before do
          allow(Gitlab::Database).to receive(:within_deprecation_notice_window?).and_return(false)
        end

        it 'only returns notice about deprecated database version' do
          is_expected.to include(a_hash_including(message: include(deprecation_warning)))
          is_expected.not_to include(a_hash_including(message: include(upcoming_deprecation_warning)))
        end
      end
    end
  end
end
