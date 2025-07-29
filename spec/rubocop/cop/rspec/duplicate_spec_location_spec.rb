# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/rspec/duplicate_spec_location'

RSpec.describe RuboCop::Cop::RSpec::DuplicateSpecLocation do
  let(:rails_root) { '../../../../' }

  def full_path(path)
    File.expand_path(File.join(rails_root, path), __dir__)
  end

  context 'for a non-EE spec file' do
    it 'registers no offenses' do
      expect_no_offenses(<<~RUBY, full_path('spec/foo_spec.rb'))
        describe 'Foo' do
        end
      RUBY
    end
  end

  context 'for a non-EE application file' do
    it 'registers no offenses' do
      expect_no_offenses(<<~RUBY, full_path('app/models/blog_post.rb'))
        class BlogPost
        end
      RUBY
    end
  end

  context 'for an EE application file' do
    it 'registers no offenses' do
      expect_no_offenses(<<~RUBY, full_path('ee/app/models/blog_post.rb'))
        class BlogPost
        end
      RUBY
    end
  end

  context 'for an EE spec file for EE only code' do
    let(:spec_file_path) { full_path('ee/spec/controllers/foo_spec.rb') }

    it 'registers no offenses' do
      expect_no_offenses(<<~RUBY, spec_file_path)
        describe 'Foo' do
        end
      RUBY
    end

    context 'when there is a duplicate file' do
      before do
        allow(File).to receive(:exist?).and_call_original

        allow(File).to receive(:exist?)
          .with(full_path('ee/spec/controllers/ee/foo_spec.rb'))
          .and_return(true)
      end

      it 'marks the describe as offending' do
        expect_offense(<<~RUBY, spec_file_path)
          describe 'Foo' do
          ^^^^^^^^^^^^^^ Duplicate spec location in `ee/spec/controllers/ee/foo_spec.rb`.
          end
        RUBY
      end
    end
  end

  context 'for an EE spec file for EE extension' do
    let(:spec_file_path) { full_path('ee/spec/controllers/ee/foo_spec.rb') }

    it 'registers no offenses' do
      expect_no_offenses(<<~RUBY, spec_file_path)
        describe 'Foo' do
        end
      RUBY
    end

    context 'when there is a duplicate file' do
      before do
        allow(File).to receive(:exist?).and_call_original

        allow(File).to receive(:exist?)
          .with(full_path('ee/spec/controllers/foo_spec.rb'))
          .and_return(true)
      end

      it 'marks the describe as offending' do
        expect_offense(<<~RUBY, spec_file_path)
          describe 'Foo' do
          ^^^^^^^^^^^^^^ Duplicate spec location in `ee/spec/controllers/foo_spec.rb`.
          end
        RUBY
      end
    end
  end
end
