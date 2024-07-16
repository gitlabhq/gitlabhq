# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Fp::RopHelpers, feature_category: :shared do
  describe '.retrieve_single_public_singleton_method' do
    let(:extending_class) do
      Class.new do
        extend Gitlab::Fp::RopHelpers

        def self.execute(class_object)
          retrieve_single_public_singleton_method(class_object)
        end
      end
    end

    let(:doc_link) do
      "https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/remote_development/README.md#functional-patterns " \
        "and https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/remote_development/README.md#railway-oriented-programming-and-the-result-class"
    end

    before do
      stub_const(class_or_module_name, class_or_module)
    end

    context "when there is exactly one public singleton method" do
      shared_examples "a class or module with a single public singleton method" do
        it "returns the single public singleton method", :unlimited_max_formatted_output_length do
          expect(extending_class.execute(class_or_module)).to eq(:public_method_one)
        end
      end

      let(:class_or_module_name) { 'ClassWithOnePublicSingletonMethod' }

      let(:expected_error_message_pattern) do
        /violation.*`#{class_or_module_name}`.*2.*found.*public_method_one, public_method_two.*private.*#{doc_link}/
      end

      context "for a class" do
        let(:class_or_module) do
          Class.new do
            def self.public_method_one
              puts 'no-op'
            end

            def self.private_method
              puts 'no-op'
            end

            private_class_method :private_method
          end
        end

        it_behaves_like "a class or module with a single public singleton method"
      end

      context "for a module" do
        let(:class_or_module) do
          Module.new do
            def self.public_method_one
              puts 'no-op'
            end

            def self.private_method
              puts 'no-op'
            end

            private_class_method :private_method
          end
        end

        it_behaves_like "a class or module with a single public singleton method"
      end
    end

    context "for invalid arguments" do
      shared_examples "a class or module without a single public singleton method" do
        it "raises an error", :unlimited_max_formatted_output_length do
          expect { extending_class.execute(class_or_module) }
            .to raise_error(ArgumentError, expected_error_message_pattern)
        end
      end

      context "when there is more than one public singleton method" do
        let(:class_or_module_name) { 'ClassWithMultiplePublicSingletonMethods' }

        let(:expected_error_message_pattern) do
          /violation.*`#{class_or_module_name}`.*2.*found.*public_method_one, public_method_two.*private.*#{doc_link}/
        end

        context "for a class" do
          let(:class_or_module) do
            Class.new do
              def self.public_method_one
                puts 'no-op'
              end

              def self.public_method_two
                puts 'no-op'
              end

              def self.private_method
                puts 'no-op'
              end

              private_class_method :private_method
            end
          end

          it_behaves_like "a class or module without a single public singleton method"
        end

        context "for a module" do
          let(:class_or_module) do
            Module.new do
              def self.public_method_one
                puts 'no-op'
              end

              def self.public_method_two
                puts 'no-op'
              end

              def self.private_method
                puts 'no-op'
              end

              private_class_method :private_method
            end
          end

          it_behaves_like "a class or module without a single public singleton method"
        end
      end

      context "when there are no public singleton methods" do
        let(:class_or_module_name) { 'ClassWithNoPublicSingletonMethods' }

        let(:expected_error_message_pattern) do
          /violation.*`#{class_or_module_name}`.*no public singleton methods were found.*#{doc_link}/
        end

        context "for a class" do
          let(:class_or_module) do
            Class.new do
              def self.private_method
                puts 'no-op'
              end

              private_class_method :private_method
            end
          end

          it_behaves_like "a class or module without a single public singleton method"
        end

        context "for a module" do
          let(:class_or_module) do
            Module.new do
              def self.private_method
                puts 'no-op'
              end

              private_class_method :private_method
            end
          end

          it_behaves_like "a class or module without a single public singleton method"
        end
      end
    end
  end
end
