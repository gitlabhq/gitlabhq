# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/qa/ee_view_in_foss_page_object'

RSpec.describe RuboCop::Cop::QA::EeViewInFossPageObject, feature_category: :test_platform do
  context 'in a FOSS QA page object' do
    before do
      allow(cop).to receive_messages(in_qa_file?: true, in_ee_qa_file?: false)
    end

    it 'registers an offense for a view pointing at an ee/ path' do
      expect_offense(<<~RUBY)
        view 'ee/app/views/x.html.haml' do
             ^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't declare an `ee/` view in a FOSS page object. Move this view (and the methods that use it) into a `qa/qa/ee/page/` extension instead.
          element 'country'
        end
      RUBY
    end

    it 'does not register an offense for a non-ee view' do
      expect_no_offenses(<<~RUBY)
        view 'app/views/admin/registrations/profiles/new.html.haml' do
          element 'first-name'
        end
      RUBY
    end

    it 'does not register an offense when the view argument is not a string' do
      expect_no_offenses(<<~RUBY)
        view some_path_variable do
          element 'country'
        end
      RUBY
    end
  end

  context 'in an EE QA page object' do
    before do
      allow(cop).to receive_messages(in_qa_file?: true, in_ee_qa_file?: true)
    end

    it 'does not register an offense for an ee/ view' do
      expect_no_offenses(<<~RUBY)
        view 'ee/app/views/x.html.haml' do
          element 'country'
        end
      RUBY
    end
  end

  # These exercise the real `in_ee_qa_file?` path resolution (no stubs) by passing
  # an absolute file path as the second argument to `expect_offense`, which sets the
  # source buffer name the cop reads.
  context 'when resolving EE files by path' do
    it 'does not flag a real EE page object (qa/qa/ee/)' do
      path = File.join(Dir.pwd, 'qa', 'qa', 'ee', 'page', 'foo.rb')

      expect_no_offenses(<<~RUBY, path)
        view 'ee/app/views/x.html.haml' do
          element 'country'
        end
      RUBY
    end

    it 'flags a sibling dir whose name merely starts with ee (qa/qa/ee_extra/)' do
      path = File.join(Dir.pwd, 'qa', 'qa', 'ee_extra', 'page', 'foo.rb')

      expect_offense(<<~RUBY, path)
        view 'ee/app/views/x.html.haml' do
             ^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't declare an `ee/` view in a FOSS page object. Move this view (and the methods that use it) into a `qa/qa/ee/page/` extension instead.
          element 'country'
        end
      RUBY
    end
  end

  context 'when outside of a QA file' do
    before do
      allow(cop).to receive(:in_qa_file?).and_return(false)
    end

    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        view 'ee/app/views/x.html.haml' do
          element 'bar'
        end
      RUBY
    end
  end
end
