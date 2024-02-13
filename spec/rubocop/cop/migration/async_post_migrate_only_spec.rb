# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/migration/async_post_migrate_only'

RSpec.describe RuboCop::Cop::Migration::AsyncPostMigrateOnly, feature_category: :database do
  let(:sample_source) do
    <<~RUBY
    def up
      %s
    end
    RUBY
  end

  let(:forbidden_method_names) { described_class::FORBIDDEN_METHODS }

  context 'when outside of a migration' do
    it 'does not register any offenses' do
      forbidden_method_names.each do |method|
        expect_no_offenses(format(sample_source, method.to_s))
      end
    end
  end

  context 'when in a migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
      allow(cop).to receive(:time_enforced?).and_return(true)
    end

    context 'when in a post deployment migration' do
      before do
        allow(cop).to receive(:in_post_deployment_migration?).and_return(true)
      end

      it 'does not register any offenses' do
        forbidden_method_names.each do |method|
          expect_no_offenses(format(sample_source, method.to_s))
        end
      end
    end

    context 'when in a regular migration' do
      it 'registers an offense' do
        forbidden_method_names.each do |method|
          expect_offense(<<~RUBY)
          def up
            #{method}
            #{'^' * method.to_s.length} #{described_class::MSG}
          end
          RUBY
        end
      end
    end
  end
end
