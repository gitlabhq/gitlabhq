# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::ImportExport::Config do
  let(:yaml_file) { described_class.new }

  describe '#to_h' do
    subject { yaml_file.to_h }

    context 'when using default config' do
      using RSpec::Parameterized::TableSyntax

      where(:ee) do
        [true, false]
      end

      with_them do
        before do
          allow(Gitlab).to receive(:ee?) { ee }
        end

        it 'parses default config' do
          expect { subject }.not_to raise_error
          expect(subject).to be_a(Hash)
          expect(subject.keys).to contain_exactly(
            :tree, :excluded_attributes, :included_attributes, :methods, :preloads, :export_reorders)
        end
      end
    end

    context 'when using custom config' do
      let(:config) do
        <<-EOF.strip_heredoc
          tree:
            project:
              - labels:
                - :priorities
              - milestones:
                - events:
                  - :push_event_payload

          included_attributes:
            user:
              - :id

          excluded_attributes:
            project:
              - :name

          methods:
            labels:
              - :type
            events:
              - :action

          preloads:
            statuses:
              project:

          ee:
            tree:
              project:
                protected_branches:
                  - :unprotect_access_levels
            included_attributes:
              user:
                - :name_ee
            excluded_attributes:
              project:
                - :name_without_ee
            methods:
              labels:
                - :type_ee
              events_ee:
                - :action_ee
            preloads:
              statuses:
                bridge_ee:
        EOF
      end

      let(:config_hash) { YAML.safe_load(config, [Symbol]) }

      before do
        allow_any_instance_of(described_class).to receive(:parse_yaml) do
          config_hash.deep_dup
        end
      end

      context 'when using CE' do
        before do
          allow(Gitlab).to receive(:ee?) { false }
        end

        it 'just returns the normalized Hash' do
          is_expected.to eq(
            {
              tree: {
                project: {
                  labels: {
                    priorities: {}
                  },
                  milestones: {
                    events: {
                      push_event_payload: {}
                    }
                  }
                }
              },
              included_attributes: {
                user: [:id]
              },
              excluded_attributes: {
                project: [:name]
              },
              methods: {
                labels: [:type],
                events: [:action]
              },
              preloads: {
                statuses: {
                  project: nil
                }
              }
            }
          )
        end
      end

      context 'when using EE' do
        before do
          allow(Gitlab).to receive(:ee?) { true }
        end

        it 'just returns the normalized Hash' do
          is_expected.to eq(
            {
              tree: {
                project: {
                  labels: {
                    priorities: {}
                  },
                  milestones: {
                    events: {
                      push_event_payload: {}
                    }
                  },
                  protected_branches: {
                    unprotect_access_levels: {}
                  }
                }
              },
              included_attributes: {
                user: [:id, :name_ee]
              },
              excluded_attributes: {
                project: [:name, :name_without_ee]
              },
              methods: {
                labels: [:type, :type_ee],
                events: [:action],
                events_ee: [:action_ee]
              },
              preloads: {
                statuses: {
                  project: nil,
                  bridge_ee: nil
                }
              }
            }
          )
        end
      end
    end
  end
end
