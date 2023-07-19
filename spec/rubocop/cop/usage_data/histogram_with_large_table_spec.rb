# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/usage_data/histogram_with_large_table'

RSpec.describe RuboCop::Cop::UsageData::HistogramWithLargeTable do
  let(:high_traffic_models) { %w[Issue Ci::Build] }
  let(:msg) { 'Avoid histogram method on' }

  let(:config) do
    RuboCop::Config.new('UsageData/HistogramWithLargeTable' => {
                          'HighTrafficModels' => high_traffic_models
                        })
  end

  context 'in an usage data file' do
    before do
      allow(cop).to receive(:in_usage_data_file?).and_return(true)
    end

    context 'with large tables' do
      context 'with one-level constants' do
        context 'when calling histogram(Issue)' do
          it 'registers an offense' do
            expect_offense(<<~CODE)
              histogram(Issue, :project_id, buckets: 1..100)
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg} Issue
            CODE
          end
        end

        context 'when calling histogram(::Issue)' do
          it 'registers an offense' do
            expect_offense(<<~CODE)
              histogram(::Issue, :project_id, buckets: 1..100)
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg} Issue
            CODE
          end
        end

        context 'when calling histogram(Issue.closed)' do
          it 'registers an offense' do
            expect_offense(<<~CODE)
              histogram(Issue.closed, :project_id, buckets: 1..100)
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg} Issue
            CODE
          end
        end

        context 'when calling histogram(::Issue.closed)' do
          it 'registers an offense' do
            expect_offense(<<~CODE)
              histogram(::Issue.closed, :project_id, buckets: 1..100)
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg} Issue
            CODE
          end
        end
      end

      context 'with two-level constants' do
        context 'when calling histogram(::Ci::Build)' do
          it 'registers an offense' do
            expect_offense(<<~CODE)
              histogram(::Ci::Build, buckets: 1..100)
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg} Ci::Build
            CODE
          end
        end

        context 'when calling histogram(::Ci::Build.active)' do
          it 'registers an offense' do
            expect_offense(<<~CODE)
              histogram(::Ci::Build.active, buckets: 1..100)
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg} Ci::Build
            CODE
          end
        end

        context 'when calling histogram(Ci::Build)' do
          it 'registers an offense' do
            expect_offense(<<~CODE)
              histogram(Ci::Build, buckets: 1..100)
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg} Ci::Build
            CODE
          end
        end

        context 'when calling histogram(Ci::Build.active)' do
          it 'registers an offense' do
            expect_offense(<<~CODE)
              histogram(Ci::Build.active, buckets: 1..100)
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{msg} Ci::Build
            CODE
          end
        end
      end
    end

    context 'with non related class' do
      it 'does not register an offense' do
        expect_no_offenses('histogram(MergeRequest, buckets: 1..100)')
      end
    end

    context 'with non related method' do
      it 'does not register an offense' do
        expect_no_offenses('count(Issue, buckets: 1..100)')
      end
    end
  end

  context 'when outside of an usage data file' do
    it 'does not register an offense' do
      expect_no_offenses('histogram(Issue, :project_id, buckets: 1..100)')
    end
  end
end
