# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/api/parameter_description'

RSpec.describe RuboCop::Cop::API::ParameterDescription, :config, feature_category: :api do
  context 'when params all have descriptions' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project owned by the user'
          optional :search,
            type: String,
            desc: "Return list of things matching the search criteria. Must be at least 4 characters."
        end
      RUBY
    end

    context "when description uses interpolation in a string" do
      it "does not add an offense" do
        expect_no_offenses(<<~'RUBY')
          params do
            requires :id, types: [String, Integer], desc: "The ID or #{interpolation_string} path of user owned project"
            optional :search,
              type: String,
              desc: "Return list of things matching the search criteria. Must be at least 4 characters."
          end
        RUBY
      end
    end

    context "when description generated using a method call" do
      it "does not add an offense" do
        expect_no_offenses(<<~RUBY)
          params do
            requires setting[:name], type: setting[:type], desc: setting[:desc]
            optional :search,
              type: String,
              desc: "Return list of things matching the search criteria. Must be at least 4 characters."
          end
        RUBY
      end
    end

    context "when description generated from a local variable" do
      it "does not add an offense" do
        expect_no_offenses(<<~RUBY)
          id_description_variable = 'The ID or URL-encoded path of the project owned by the user'
          params do
            requires :id, types: [String, Integer], desc: id_description_variable
            optional :search,
              type: String,
              desc: "Return list of things matching the search criteria. Must be at least 4 characters."
          end
        RUBY
      end
    end
  end

  context 'when param does not have a description' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        params do
          requires :id, types: [String, Integer]
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ API params must include a desc.
          optional :search,
            type: String,
            desc: "Return list of things matching the search criteria. Must be at least 4 characters."
        end
      RUBY
    end
  end

  context 'when param is a hash type' do
    context 'when parent param has description' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          params do
            requires :current_file, type: Hash, desc: "File information for actions" do
            requires :file_name, type: String, limit: 255, desc: 'The name of the current file'
            optional :content, type: String, desc: 'The content'
            end
          end
        RUBY
      end
    end

    context 'when parent param does not have a description' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          params do
            requires :current_file, type: Hash do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ API params must include a desc.
            requires :file_name, type: String, limit: 255, desc: 'The name of the current file'
            optional :content, type: String, desc: 'The content'
            end
          end
        RUBY
      end
    end
  end

  context 'with hidden params' do
    it 'does not register an offense for hidden params without a description' do
      expect_no_offenses(<<~RUBY)
        params do
          requires :invisible, type: String, documentation: { hidden: true }
        end
      RUBY
    end
  end
end
