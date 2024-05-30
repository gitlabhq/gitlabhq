# frozen_string_literal: true

require 'rspec-parameterized'
require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'
require_relative '../../../tooling/danger/customer_success'

RSpec.describe Tooling::Danger::CustomerSuccess do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:customer_success) { fake_danger.new(helper: fake_helper) }

  describe 'customer success danger' do
    using RSpec::Parameterized::TableSyntax

    where do
      {
        'with data category changes to Ops and no Customer Success::Impact Check label' => {
          modified_files: %w[config/metrics/20210216182127_user_secret_detection_jobs.yml app/models/user.rb],
          changed_lines: ['-data_category: cat1', '+data_category: operational'],
          customer_labeled: false,
          impacted: true,
          impacted_files: %w[config/metrics/20210216182127_user_secret_detection_jobs.yml]
        },
        'with data category changes and Customer Success::Impact Check label' => {
          modified_files: %w[config/metrics/20210216182127_user_secret_detection_jobs.yml],
          changed_lines: ['-data_category: cat1', '+data_category: operational'],
          customer_labeled: true,
          impacted: false,
          impacted_files: %w[config/metrics/20210216182127_user_secret_detection_jobs.yml]
        },
        'with metric file changes and no data category changes' => {
          modified_files: %w[config/metrics/20210216182127_user_secret_detection_jobs.yml],
          changed_lines: ['-product_group: activation'],
          customer_labeled: false,
          impacted: false,
          impacted_files: []
        },
        'with data category changes from Ops' => {
          modified_files: %w[config/metrics/20210216182127_user_secret_detection_jobs.yml app/models/user.rb],
          changed_lines: ['-data_category: operational', '+data_category: cat2'],
          customer_labeled: false,
          impacted: true,
          impacted_files: %w[config/metrics/20210216182127_user_secret_detection_jobs.yml]
        },
        'with data category removed' => {
          modified_files: %w[config/metrics/20210216182127_user_secret_detection_jobs.yml app/models/user.rb],
          changed_lines: ['-data_category: operational'],
          customer_labeled: false,
          impacted: true,
          impacted_files: %w[config/metrics/20210216182127_user_secret_detection_jobs.yml]
        },
        'with data category added' => {
          modified_files: %w[config/metrics/20210216182127_user_secret_detection_jobs.yml app/models/user.rb],
          changed_lines: ['+data_category: operational'],
          customer_labeled: false,
          impacted: true,
          impacted_files: %w[config/metrics/20210216182127_user_secret_detection_jobs.yml]
        },
        'with data category in uppercase' => {
          modified_files: %w[config/metrics/20210216182127_user_secret_detection_jobs.yml app/models/user.rb],
          changed_lines: ['+data_category: Operational'],
          customer_labeled: false,
          impacted: true,
          impacted_files: %w[config/metrics/20210216182127_user_secret_detection_jobs.yml]
        }
      }
    end

    with_them do
      before do
        allow(fake_helper).to receive(:modified_files).and_return(modified_files)
        allow(fake_helper).to receive(:changed_lines).and_return(changed_lines)
        allow(fake_helper).to receive(:has_scoped_label_with_scope?).and_return(customer_labeled)
        allow(fake_helper).to receive(:markdown_list).with(impacted_files)
                                .and_return(impacted_files.map { |item| "* `#{item}`" }.join("\n"))
      end

      it 'generates correct message' do
        expect(customer_success.build_message).to match_expected_message
      end
    end
  end

  def match_expected_message
    return be_nil unless impacted

    start_with(described_class::CHANGED_SCHEMA_MESSAGE).and(include(*impacted_files))
  end
end
