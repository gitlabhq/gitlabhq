# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/performance/ar_exists_and_present_blank'

RSpec.describe RuboCop::Cop::Performance::ARExistsAndPresentBlank do
  context 'when it is not haml file' do
    it 'does not flag it as an offense' do
      expect(cop).to receive(:in_haml_file?).with(anything).at_least(:once).and_return(false)

      expect_no_offenses <<~RUBY
        return unless @users.exists?
        show @users if @users.present?
      RUBY
    end
  end

  context 'when it is haml file' do
    before do
      expect(cop).to receive(:in_haml_file?).with(anything).at_least(:once).and_return(true)
    end

    context 'the same object uses exists? and present?' do
      it 'flags it as an offense' do
        expect_offense <<~RUBY
        return unless @users.exists?
        show @users if @users.present?
                       ^^^^^^^^^^^^^^^ Avoid `@users.present?`, because it will generate database query 'Select TABLE.*' which is expensive. Suggest to use `@users.any?` to replace `@users.present?`
        RUBY
      end
    end

    context 'the same object uses exists? and blank?' do
      it 'flags it as an offense' do
        expect_offense <<~RUBY
        return unless @users.exists?
        show @users if @users.blank?
                       ^^^^^^^^^^^^^ Avoid `@users.blank?`, because it will generate database query 'Select TABLE.*' which is expensive. Suggest to use `@users.empty?` to replace `@users.blank?`
        RUBY
      end
    end

    context 'the same object uses exists?, blank? and present?' do
      it 'flags it as an offense' do
        expect_offense <<~RUBY
        return unless @users.exists?
        show @users if @users.blank?
                       ^^^^^^^^^^^^^ Avoid `@users.blank?`, because it will generate database query 'Select TABLE.*' which is expensive. Suggest to use `@users.empty?` to replace `@users.blank?`
        show @users if @users.present?
                       ^^^^^^^^^^^^^^^ Avoid `@users.present?`, because it will generate database query 'Select TABLE.*' which is expensive. Suggest to use `@users.any?` to replace `@users.present?`
        RUBY
      end
    end

    RSpec.shared_examples 'different object uses exists? and present?/blank?' do |another_method|
      it 'does not flag it as an offense' do
        expect_no_offenses <<~RUBY
        return unless @users.exists?
        present @emails if @emails.#{another_method}
        RUBY
      end
    end

    it_behaves_like 'different object uses exists? and present?/blank?', 'present?'
    it_behaves_like 'different object uses exists? and present?/blank?', 'blank?'

    RSpec.shared_examples 'Only using one present?/blank? without exists?' do |non_exists_method|
      it 'does not flag it as an offense' do
        expect_no_offenses "@users.#{non_exists_method}"
      end
    end

    it_behaves_like 'Only using one present?/blank? without exists?', 'present?'
    it_behaves_like 'Only using one present?/blank? without exists?', 'blank?'

    context 'when using many present?/empty? without exists?' do
      it 'does not flag it as an offense' do
        expect_no_offenses <<~RUBY
        @user.present?
        @user.blank?
        @user.present?
        @user.blank?
        RUBY
      end
    end

    context 'when just using exists? without present?/blank?' do
      it 'does not flag it as an offense' do
        expect_no_offenses '@users.exists?'

        expect_no_offenses <<~RUBY
        @users.exists?
        @users.some_other_method?
        @users.exists?
        RUBY
      end
    end
  end
end
