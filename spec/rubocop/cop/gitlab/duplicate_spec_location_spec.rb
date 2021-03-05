# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../rubocop/cop/gitlab/duplicate_spec_location'

RSpec.describe RuboCop::Cop::Gitlab::DuplicateSpecLocation do
  subject(:cop) { described_class.new }

  let(:rails_root) { '../../../../' }

  def full_path(path)
    File.expand_path(File.join(rails_root, path), __dir__)
  end

  context 'Non-EE spec file' do
    it 'registers no offenses' do
      expect_no_offenses(<<~SOURCE, full_path('spec/foo_spec.rb'))
        describe 'Foo' do
        end
      SOURCE
    end
  end

  context 'Non-EE application file' do
    it 'registers no offenses' do
      expect_no_offenses(<<~SOURCE, full_path('app/models/blog_post.rb'))
        class BlogPost
        end
      SOURCE
    end
  end

  context 'EE application file' do
    it 'registers no offenses' do
      expect_no_offenses(<<~SOURCE, full_path('ee/app/models/blog_post.rb'))
        class BlogPost
        end
      SOURCE
    end
  end

  context 'EE spec file for EE only code' do
    let(:spec_file_path) { full_path('ee/spec/controllers/foo_spec.rb') }

    it 'registers no offenses' do
      expect_no_offenses(<<~SOURCE, spec_file_path)
        describe 'Foo' do
        end
      SOURCE
    end

    context 'there is a duplicate file' do
      before do
        allow(File).to receive(:exist?).and_call_original

        allow(File).to receive(:exist?)
          .with(full_path('ee/spec/controllers/ee/foo_spec.rb'))
          .and_return(true)
      end

      it 'marks the describe as offending' do
        expect_offense(<<~SOURCE, spec_file_path)
          describe 'Foo' do
          ^^^^^^^^^^^^^^ Duplicate spec location in `ee/spec/controllers/ee/foo_spec.rb`.
          end
        SOURCE
      end
    end
  end

  context 'EE spec file for EE extension' do
    let(:spec_file_path) { full_path('ee/spec/controllers/ee/foo_spec.rb') }

    it 'registers no offenses' do
      expect_no_offenses(<<~SOURCE, spec_file_path)
        describe 'Foo' do
        end
      SOURCE
    end

    context 'there is a duplicate file' do
      before do
        allow(File).to receive(:exist?).and_call_original

        allow(File).to receive(:exist?)
          .with(full_path('ee/spec/controllers/foo_spec.rb'))
          .and_return(true)
      end

      it 'marks the describe as offending' do
        expect_offense(<<~SOURCE, spec_file_path)
          describe 'Foo' do
          ^^^^^^^^^^^^^^ Duplicate spec location in `ee/spec/controllers/foo_spec.rb`.
          end
        SOURCE
      end
    end
  end
end
