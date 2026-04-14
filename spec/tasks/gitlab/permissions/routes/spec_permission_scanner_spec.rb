# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Tasks::Gitlab::Permissions::Routes::SpecPermissionScanner, feature_category: :permissions do
  let(:scanner) { described_class.new }

  describe '#in_todo?' do
    before do
      allow(scanner).to receive(:todo_entries).and_return(Set.new)
    end

    context 'when the permission is in the TODO file' do
      before do
        allow(scanner).to receive(:todo_entries).and_return(Set.new(['read_note']))
      end

      it 'returns true' do
        expect(scanner.in_todo?(:read_note)).to be true
      end
    end

    context 'when the permission is not in the TODO file' do
      it 'returns false' do
        expect(scanner.in_todo?(:read_note)).to be false
      end
    end
  end

  describe '#add_route and #insufficient_test_coverage' do
    let(:route_info) do
      { method: 'GET', path: '/projects/:id/test', source: 'lib/api/test.rb:42',
        spec_file: 'spec/requests/api/test_spec.rb' }
    end

    before do
      allow(scanner).to receive_messages(spec_files: [], build_shared_example_inclusions: Hash.new(0),
        todo_entries: Set.new)
    end

    it 'returns violations for permissions with insufficient tests' do
      scanner.add_route(route_id: 'GET /projects/:id/test', permission: :read_project, route_info: route_info)

      result = scanner.insufficient_test_coverage
      expect(result).to contain_exactly(
        hash_including(permission: 'read_project', route_count: 1, test_count: 0)
      )
    end

    it 'deduplicates routes with the same route_id and permission' do
      2.times do
        scanner.add_route(route_id: 'GET /projects/:id/test', permission: :read_project, route_info: route_info)
      end

      result = scanner.insufficient_test_coverage
      expect(result.first[:route_count]).to eq(1)
    end

    it 'skips permissions in the TODO file' do
      allow(scanner).to receive(:todo_entries).and_return(Set.new(['read_project']))
      scanner.add_route(route_id: 'GET /projects/:id/test', permission: :read_project, route_info: route_info)

      expect(scanner.insufficient_test_coverage).to be_empty
    end

    it 'includes route details in violations' do
      scanner.add_route(route_id: 'GET /projects/:id/test', permission: :read_project, route_info: route_info)

      result = scanner.insufficient_test_coverage
      expect(result.first[:routes]).to contain_exactly(route_info)
    end
  end

  describe '#test_count' do
    before do
      allow(scanner).to receive_messages(spec_files: ['test.rb'], build_shared_example_inclusions: Hash.new(0))
    end

    it 'counts concrete permission occurrences' do
      content = <<~RUBY
        it_behaves_like 'authorizing granular token permissions', :read_project do
        end
        it_behaves_like 'authorizing granular token permissions', :read_project do
        end
      RUBY
      allow(File).to receive(:read).with('test.rb').and_return(content)

      expect(scanner.test_count(:read_project)).to eq(2)
    end

    it 'counts dynamic pattern matches' do
      content = 'it_behaves_like \'authorizing granular token permissions\', :"read_#{noteable_type}_discussion" do'
      allow(File).to receive(:read).with('test.rb').and_return(content)

      expect(scanner.test_count(:read_issue_discussion)).to eq(1)
      expect(scanner.test_count(:read_merge_request_discussion)).to eq(1)
      expect(scanner.test_count(:create_issue_discussion)).to eq(0)
    end
  end

  describe 'permission extraction' do
    before do
      allow(scanner).to receive_messages(spec_files: ['test.rb'], build_shared_example_inclusions: Hash.new(0))
    end

    it 'extracts single symbol permissions' do
      content = "it_behaves_like 'authorizing granular token permissions', :read_project do"
      allow(File).to receive(:read).with('test.rb').and_return(content)

      expect(scanner.test_count(:read_project)).to eq(1)
    end

    it 'extracts array permissions' do
      content = "it_behaves_like 'authorizing granular token permissions', [:read_project, :read_issue] do"
      allow(File).to receive(:read).with('test.rb').and_return(content)

      expect(scanner.test_count(:read_project)).to eq(1)
      expect(scanner.test_count(:read_issue)).to eq(1)
    end

    it 'extracts %i array permissions' do
      content = "it_behaves_like 'authorizing granular token permissions', %i[read_project read_issue] do"
      allow(File).to receive(:read).with('test.rb').and_return(content)

      expect(scanner.test_count(:read_project)).to eq(1)
      expect(scanner.test_count(:read_issue)).to eq(1)
    end

    it 'ignores dynamic variable references' do
      content = "it_behaves_like 'authorizing granular token permissions', permission do"
      allow(File).to receive(:read).with('test.rb').and_return(content)

      expect(scanner.test_count(:permission)).to eq(0)
    end

    it 'handles permissions with extra arguments' do
      content = "it_behaves_like 'authorizing granular token permissions', " \
        ":read_project, expected_success_status: :ok do"
      allow(File).to receive(:read).with('test.rb').and_return(content)

      expect(scanner.test_count(:read_project)).to eq(1)
    end

    it 'extracts permissions from wrapper shared examples' do
      content = "it_behaves_like 'granular token permissions authorizable', :download_debian_distribution_release"
      allow(File).to receive(:read).with('test.rb').and_return(content)

      expect(scanner.test_count(:download_debian_distribution_release)).to eq(1)
    end

    it 'handles multiline permission arguments' do
      content = <<~RUBY
        it_behaves_like 'authorizing granular token permissions',
          :read_project do
        end
      RUBY
      allow(File).to receive(:read).with('test.rb').and_return(content)

      expect(scanner.test_count(:read_project)).to eq(1)
    end

    it 'handles multiline dynamic symbol permission arguments' do
      content = <<~'RUBY'
        it_behaves_like 'authorizing granular token permissions',
          :"read_#{eventable_type}_state_event" do
        end
      RUBY
      allow(File).to receive(:read).with('test.rb').and_return(content)

      expect(scanner.test_count(:read_issue_state_event)).to eq(1)
      expect(scanner.test_count(:read_merge_request_state_event)).to eq(1)
    end
  end

  describe 'shared example multiplier' do
    before do
      allow(scanner).to receive(:spec_files).and_return(
        ['shared_example.rb', 'spec_a.rb', 'spec_b.rb']
      )
    end

    it 'multiplies permissions by global inclusion count' do
      shared_content = <<~RUBY
        shared_examples 'access request endpoints' do
          it_behaves_like 'authorizing granular token permissions', :read_access_request do
          end
        end
      RUBY

      spec_a_content = <<~RUBY
        it_behaves_like 'access request endpoints'
      RUBY

      spec_b_content = <<~RUBY
        it_behaves_like 'access request endpoints'
      RUBY

      allow(File).to receive(:read).with('shared_example.rb').and_return(shared_content)
      allow(File).to receive(:read).with('spec_a.rb').and_return(spec_a_content)
      allow(File).to receive(:read).with('spec_b.rb').and_return(spec_b_content)

      expect(scanner.test_count(:read_access_request)).to eq(2)
    end

    it 'multiplies dynamic patterns by global inclusion count' do
      shared_content = <<~'RUBY'
        shared_examples 'time tracking endpoints' do
          it_behaves_like 'authorizing granular token permissions', :"read_#{issuable_name}_time_statistic" do
          end
        end
      RUBY

      spec_a_content = <<~RUBY
        it_behaves_like 'time tracking endpoints'
      RUBY

      spec_b_content = <<~RUBY
        it_behaves_like 'time tracking endpoints'
      RUBY

      allow(File).to receive(:read).with('shared_example.rb').and_return(shared_content)
      allow(File).to receive(:read).with('spec_a.rb').and_return(spec_a_content)
      allow(File).to receive(:read).with('spec_b.rb').and_return(spec_b_content)

      expect(scanner.test_count(:read_issue_time_statistic)).to eq(2)
      expect(scanner.test_count(:read_merge_request_time_statistic)).to eq(2)
    end

    it 'returns 1 for permissions not inside a shared example' do
      content = <<~RUBY
        it_behaves_like 'authorizing granular token permissions', :read_project do
        end
      RUBY

      allow(File).to receive(:read).with('shared_example.rb').and_return('')
      allow(File).to receive(:read).with('spec_a.rb').and_return(content)
      allow(File).to receive(:read).with('spec_b.rb').and_return('')

      expect(scanner.test_count(:read_project)).to eq(1)
    end
  end

  describe '#derive_spec_path' do
    it 'maps lib/api/ to spec/requests/api/' do
      expect(scanner.derive_spec_path('lib/api/notes.rb')).to eq('spec/requests/api/notes_spec.rb')
    end

    it 'maps ee/lib/api/ to ee/spec/requests/api/' do
      expect(scanner.derive_spec_path('ee/lib/api/epics.rb')).to eq('ee/spec/requests/api/epics_spec.rb')
    end

    it 'maps ee/lib/ee/api/ to ee/spec/requests/api/' do
      expect(scanner.derive_spec_path('ee/lib/ee/api/groups.rb')).to eq('ee/spec/requests/api/groups_spec.rb')
    end

    it 'handles nested paths' do
      expect(scanner.derive_spec_path('lib/api/ci/pipelines.rb')).to eq('spec/requests/api/ci/pipelines_spec.rb')
    end
  end
end
