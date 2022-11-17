# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ShaAttribute do
  let(:model) do
    Class.new(ActiveRecord::Base) do
      include ShaAttribute

      self.table_name = 'merge_requests'
    end
  end

  let(:binary_column) { :merge_ref_sha }
  let(:text_column) { :target_branch }

  describe '.sha_attribute' do
    it 'defines a SHA attribute with Gitlab::Database::ShaAttribute type' do
      expect(model).to receive(:attribute)
        .with(binary_column, an_instance_of(Gitlab::Database::ShaAttribute))
        .and_call_original

      model.sha_attribute(binary_column)
    end
  end

  describe '.sha256_attribute' do
    it 'defines a SHA256 attribute with Gitlab::Database::ShaAttribute type' do
      expect(model).to receive(:attribute)
        .with(binary_column, an_instance_of(Gitlab::Database::Sha256Attribute))
        .and_call_original

      model.sha256_attribute(binary_column)
    end
  end

  describe '.load_schema!' do
    # load_schema! is not a documented class method, so use a documented method
    # that we know will call load_schema!
    def load_schema!
      expect(model).to receive(:load_schema!).and_call_original

      model.new
    end

    using RSpec::Parameterized::TableSyntax

    where(:column_name, :environment, :expected_error) do
      ref(:binary_column)    | 'development' | :no_error
      ref(:binary_column)    | 'production'  | :no_error
      ref(:text_column)      | 'development' | :sha_mismatch_error
      ref(:text_column)      | 'production'  | :no_error
      :__non_existent_column | 'development' | :no_error
      :__non_existent_column | 'production'  | :no_error
    end

    let(:sha_mismatch_error) do
      [
        described_class::ShaAttributeTypeMismatchError,
        /#{column_name}.* should be a :binary column/
      ]
    end

    with_them do
      before do
        stub_rails_env(environment)
      end

      context 'with sha_attribute' do
        before do
          model.sha_attribute(column_name)
        end

        it 'validates column type' do
          case expected_error
          when :no_error
            expect { load_schema! }.not_to raise_error
          when :sha_mismatch_error
            expect { load_schema! }.to raise_error(
              described_class::ShaAttributeTypeMismatchError,
              /sha_attribute.*#{column_name}.* should be a :binary column/
            )
          end
        end
      end

      context 'with sha256_attribute' do
        before do
          model.sha256_attribute(column_name)
        end

        it 'validates column type' do
          case expected_error
          when :no_error
            expect { load_schema! }.not_to raise_error
          when :sha_mismatch_error
            expect { load_schema! }.to raise_error(
              described_class::Sha256AttributeTypeMismatchError,
              /sha256_attribute.*#{column_name}.* should be a :binary column/
            )
          end
        end
      end
    end
  end
end
