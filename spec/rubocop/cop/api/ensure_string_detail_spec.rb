# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/api/ensure_string_detail'

RSpec.describe RuboCop::Cop::API::EnsureStringDetail do
  context "when in_api? == true" do
    before do
      allow(cop).to receive(:in_api?).and_return(true)
    end

    context "when detail field uses a string" do
      it "does not add an offense" do
        expect_no_offenses(<<~CODE)
          class SomeAPI
            resource :projects do
              desc 'Some API thing related to a project' do
                detail "foo bar"
              end
            end
          end
        CODE
      end
    end

    context "when detail field uses interpolation in a string" do
      it "does not add an offense" do
        baz = "bat"

        expect_no_offenses(<<~CODE)
          class SomeAPI
            resource :projects do
              desc 'Some API thing related to a project' do
                detail "foo bar #{baz}"
              end
            end
          end
        CODE
      end
    end

    context "when detail field uses a multiline string" do
      it "does not add an offense" do
        expect_no_offenses(<<~CODE)
          class SomeAPI
            resource :projects do
              desc 'Some API thing related to a project' do
                detail "foo bar"\
                  "baz bat"
              end
            end
          end
        CODE
      end
    end

    context "when detail field uses a constant" do
      it "does not add an offense" do
        pending

        expect_no_offenses(<<~CODE)
          class SomeAPI
            resource :projects do
              DESCRIPTION = 'A string'

              desc 'Some API thing related to a project' do
                detail DESCRIPTION
              end
            end
          end
        CODE
      end
    end

    context "when detail field uses a HEREDOC string" do
      it "does not add an offense" do
        expect_no_offenses(<<~CODE)
          class SomeAPI
            resource :projects do
              desc 'Some API thing related to a project' do
                detail <<~END
                  foo bar
                  baz bat
                END
              end
            end
          end
        CODE
      end
    end

    context "when detail field uses an array" do
      it "adds an offense" do
        expect_offense(<<~CODE)
          class SomeAPI
            resource :projects do
              desc 'Some API thing related to a project' do
                something 'else'
                detail ["foo", "bar"]
                ^^^^^^^^^^^^^^^^^^^^^ Only String objects are permitted in API detail field.
              end
            end
          end
        CODE
      end
    end

    context "when detail field is outside of desc block" do
      it "does not add an offense" do
        expect_no_offenses(<<~CODE)
          class Foo
            detail ["foo", "bar"]
          end
        CODE
      end
    end
  end

  context "when in_api? == false" do
    before do
      allow(cop).to receive(:in_api?).and_return(false)
    end

    it "does not add an offense" do
      expect_no_offenses(<<~CODE)
        class SomeAPI
          resource :projects do
            desc 'Some API thing related to a project' do
              detail ["foo", "bar"]
            end
          end
        end
      CODE
    end
  end
end
