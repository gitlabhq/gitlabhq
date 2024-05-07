# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::TerraformModule::Metadata::ParseHclFileService, feature_category: :package_registry do
  subject(:service) { described_class.new(file) }

  describe '#parse' do
    subject(:response) { service.execute.payload }

    context 'when the file is empty' do
      let(:file) { '' }

      it { is_expected.to be_empty }
    end

    context 'when the file is not empty' do
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

        it 'returns the variables' do
          expect(response[:variables]).to match_array(
            [
              {
                'name' => 'bucket_name',
                'description' => ' A unique bucket name to store files. Must be unique across all of AWS.',
                'type' => 'string'
              },
              {
                'default' => 'us-west-2',
                'description' => 'The AWS region to deploy to.',
                'name' => 'region',
                'type' => 'object({ name = string id = number })'
              }
            ]
          )
        end
      end

      context 'for outputs' do
        let(:file) do
          StringIO.new(
            <<~HCL
              output "bucket_name" {
                description = "The name of the bucket."
              }

              output "region" {
                value = var.region.name
                description = "The AWS region to deploy to."
              }
          HCL
          )
        end

        it 'returns the outputs' do
          expect(response[:outputs]).to match_array(
            [
              {
                'description' => 'The name of the bucket.',
                'name' => 'bucket_name'
              },
              {
                'description' => 'The AWS region to deploy to.',
                'name' => 'region'
              }
            ]
          )
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

        it 'returns the resources' do
          expect(response[:resources]).to match_array(['aws_s3_bucket.bucket', 'aws_instance.web'])
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

              module "rds" {
                source = "modules/rds"
                version = "~> 3.9"
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

        it 'returns the dependencies' do
          expect(response[:modules]).to match_array(
            [
              { 'name' => 'vpc', 'source' => 'terraform-aws-modules/vpc/aws', 'version' => '2.0.0' },
              { 'name' => 'rds', 'source' => 'modules/rds', 'version' => '~> 3.9' }
            ]
          )

          expect(response[:providers]).to match_array(
            [
              { 'name' => 'aws' },
              { 'name' => 'gitlab', 'version' => '~> 1.0' },
              { 'name' => 'aws', 'source' => 'hashicorp/aws', 'version' => '> 3.0.0' },
              { 'name' => 'google', 'source' => 'hashicorp/google', 'version' => '>= 4.28, < 6' }
            ]
          )
        end
      end
    end
  end
end
