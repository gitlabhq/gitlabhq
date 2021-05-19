# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/performance/ar_count_each'

RSpec.describe RuboCop::Cop::Performance::ARCountEach do
  subject(:cop) { described_class.new }

  context 'when it is not haml file' do
    it 'does not flag it as an offense' do
      expect(subject).to receive(:in_haml_file?).with(anything).at_least(:once).and_return(false)

      expect_no_offenses <<~SOURCE
        show(@users.count)
        @users.each { |user| display(user) }
      SOURCE
    end
  end

  context 'when it is haml file' do
    before do
      expect(subject).to receive(:in_haml_file?).with(anything).at_least(:once).and_return(true)
    end

    context 'when the same object uses count and each' do
      it 'flags it as an offense' do
        expect_offense <<~SOURCE
        show(@users.count)
             ^^^^^^^^^^^^ If @users is AR relation, avoid `@users.count ...; @users.each... `, this will trigger two queries. Use `@users.load.size ...; @users.each... ` instead. If @users is an array, try to use @users.size.
        @users.each { |user| display(user) }
        SOURCE
      end
    end

    context 'when different object uses count and each' do
      it 'does not flag it as an offense' do
        expect_no_offenses <<~SOURCE
        show(@emails.count)
        @users.each { |user| display(user) }
        SOURCE
      end
    end

    context 'when just using count without each' do
      it 'does not flag it as an offense' do
        expect_no_offenses '@users.count'
      end
    end

    context 'when just using each without count' do
      it 'does not flag it as an offense' do
        expect_no_offenses '@users.each { |user| display(user) }'
      end
    end
  end
end
