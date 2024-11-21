# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::TerraformModule::Metadata::ProcessFileService, feature_category: :package_registry do
  let(:file) { 'file' }
  let(:path) { 'path' }
  let(:module_type) { :root }
  let(:service) { described_class.new(file, path, module_type) }

  describe '#execute' do
    subject(:execute) { service.execute }

    context 'when the file is a README' do
      let(:path) { 'README' }
      let(:file) { StringIO.new('README file') }

      it 'returns a success response with the parsed README' do
        is_expected.to be_success
        expect(execute.payload).to eq({ root: { readme: 'README file' } })
      end
    end

    context 'when the file is a Terraform file' do
      %w[root submodules examples].each do |section|
        context "when the file is a Terraform #{section} file" do
          let(:path) { section == 'root' ? './main.tf' : "./#{section.sub('sub', '')}/module_name/main.tf" }
          let(:module_type) { section.singularize.to_sym }

          context 'for variables' do
            let(:file) do
              StringIO.new(
                <<~HCL
                    variable "bucket_name" {
                      description = <<EOD
                        A unique bucket name to store files.
                        Must be unique across all of AWS.
                      EOD
                      type = string
                    }

                    variable "region" {
                      type = object({
                        name = string
                        id = number
                      })
                      description = "The AWS region to deploy to."
                      default = "us-west-2"
                      validation {
                        condition = var.region.name != ""
                        error_message = "The region name cannot be empty."
                      }
                      nullable = false
                      sensitive = false
                    }
                HCL
              )
            end

            it 'returns a success response with the parsed variables' do
              expect_next_instance_of(::Packages::TerraformModule::Metadata::ParseHclFileService, file) do |parser|
                expect(parser).to receive(:execute).and_call_original
              end

              is_expected.to be_success
              expect(execute.payload).to eq(build_module_type_hash(section, {
                dependencies: { modules: [], providers: [] },
                inputs: [
                  { 'description' => ' A unique bucket name to store files. Must be unique across all of AWS.',
                    'name' => 'bucket_name',
                    'type' => 'string' },
                  { 'default' => 'us-west-2',
                    'description' => 'The AWS region to deploy to.',
                    'name' => 'region',
                    'type' => 'object({ name = string id = number })' }
                ],
                outputs: [], resources: []
              }))
            end
          end

          context 'for outputs' do
            let(:file) do
              StringIO.new(
                <<~HCL
                    output "bucket_name" {
                      description = "The name of the bucket."
                      value = aws_s3_bucket.bucket_name
                    }

                    output "region" {
                      value = var.region
                      description = "The AWS region to deploy to."
                    }
                HCL
              )
            end

            it 'returns a success response with the parsed outputs' do
              expect_next_instance_of(::Packages::TerraformModule::Metadata::ParseHclFileService, file) do |parser|
                expect(parser).to receive(:execute).and_call_original
              end

              is_expected.to be_success
              expect(execute.payload).to eq(build_module_type_hash(section, {
                dependencies: { modules: [], providers: [] },
                inputs: [],
                outputs: [
                  { 'description' => 'The name of the bucket.',
                    'name' => 'bucket_name' },
                  { 'description' => 'The AWS region to deploy to.',
                    'name' => 'region' }
                ],
                resources: []
              }))
            end
          end

          context 'for resources' do
            let(:file) do
              StringIO.new(
                <<~HCL
                    resource "aws_s3_bucket" "bucket" {
                      bucket = var.bucket_name
                      acl = "private"
                    }

                    resource "aws_instance" "web" {
                      ami = "ami-0c55b159cbfafe1f0"
                      instance_type = "t2.micro"
                    }
                HCL
              )
            end

            it 'returns a success response with the parsed resources' do
              expect_next_instance_of(::Packages::TerraformModule::Metadata::ParseHclFileService, file) do |parser|
                expect(parser).to receive(:execute).and_call_original
              end

              is_expected.to be_success
              expect(execute.payload).to eq(build_module_type_hash(section, {
                dependencies: { modules: [], providers: [] },
                inputs: [],
                outputs: [],
                resources: ['aws_s3_bucket.bucket', 'aws_instance.web']
              }))
            end
          end

          context 'for dependencies' do
            let(:file) do
              StringIO.new(
                <<~HCL
                    module "vpc" {
                      source = "terraform-aws-modules/vpc/aws"
                      version = "2.0.0"
                      region = var.region
                    }

                    module "ec2" {
                      source = "./modules/ec2"
                      version = "2.0.0"
                    }

                    provider "aws" {
                      region = var.region
                      version = "3.0.0"
                    }

                    terraform {
                      required_version = ">= 0.12"
                      required_providers {
                        gitlab = "~> 1.0"

                        aws = {
                          source = "hashicorp/aws"
                          version = "> 3.0.0"
                        }

                        google = {
                          version = ">= 4.28, < 6"
                          source = "hashicorp/google"
                        }
                      }
                      provider_meta "aws" {
                        build_tags = ["aws"]
                      }
                    }
                HCL
              )
            end

            it 'returns a success response with the parsed dependencies' do
              expect_next_instance_of(::Packages::TerraformModule::Metadata::ParseHclFileService, file) do |parser|
                expect(parser).to receive(:execute).and_call_original
              end

              is_expected.to be_success
              expect(execute.payload).to eq(build_module_type_hash(section, {
                dependencies: {
                  modules: [{ 'name' => 'vpc', 'source' => 'terraform-aws-modules/vpc/aws', 'version' => '2.0.0' }],
                  providers: [
                    { 'name' => 'aws' },
                    { 'name' => 'gitlab', 'version' => '~> 1.0' },
                    { 'name' => 'aws', 'source' => 'hashicorp/aws', 'version' => '> 3.0.0' },
                    { 'name' => 'google', 'source' => 'hashicorp/google', 'version' => '>= 4.28, < 6' }
                  ]
                },
                inputs: [],
                outputs: [],
                resources: []
              }))
            end
          end
        end
      end
    end

    def build_module_type_hash(key, content)
      if key == 'root'
        { root: content }
      else
        { key.to_sym => { 'module_name' => content } }
      end
    end

    context 'when an error occurs' do
      before do
        allow_next_instance_of(::Packages::TerraformModule::Metadata::ParseHclFileService) do |parser|
          allow(parser).to receive(:execute).and_raise(StandardError)
        end
      end

      it 'rescues the error and tracks it' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          an_instance_of(StandardError),
          class: described_class.name
        )

        execute
      end

      it_behaves_like 'returning an error service response', message: 'Error processing path'
    end
  end
end
