# frozen_string_literal: true

require 'fast_spec_helper'
require 'tempfile'
require_relative '../../../scripts/accessibility_generator/code_pattern_extractor'

RSpec.describe CodePatternExtractor, feature_category: :tooling do
  let(:gitlab_root) { Dir.mktmpdir }
  let(:extractor) { described_class.new(gitlab_root) }

  after do
    FileUtils.rm_rf(gitlab_root)
  end

  describe '#extract_patterns' do
    context 'with setup patterns' do
      it 'extracts let_it_be blocks with create calls' do
        create_test_file('spec/features/test_spec.rb', <<~RUBY)
          RSpec.describe 'Test' do
            let_it_be(:user) { create(:user) }
            let_it_be(:project) { create(:project, :repository) }

            it 'does something' do
              # test code
            end
          end
        RUBY

        patterns = extractor.extract_patterns(['spec/features/test_spec.rb'])

        expect(patterns['setup']).to include('let_it_be(:user) { create(:user) }')
        expect(patterns['setup']).to include('let_it_be(:project) { create(:project, :repository) }')
      end

      it 'extracts let blocks with create calls' do
        create_test_file('spec/features/test_spec.rb', <<~RUBY)
          RSpec.describe 'Test' do
            let(:user) { create(:user) }
            let(:issue) { create(:issue, project: project) }

            it 'does something' do
              # test code
            end
          end
        RUBY

        patterns = extractor.extract_patterns(['spec/features/test_spec.rb'])

        expect(patterns['setup']).to include('let(:user) { create(:user) }')
        expect(patterns['setup']).to include('let(:issue) { create(:issue, project: project) }')
      end

      it 'ignores let blocks without create calls' do
        create_test_file('spec/features/test_spec.rb', <<~RUBY)
          RSpec.describe 'Test' do
            let(:name) { 'John' }
            let(:user) { create(:user) }

            it 'does something' do
              # test code
            end
          end
        RUBY

        patterns = extractor.extract_patterns(['spec/features/test_spec.rb'])

        expect(patterns['setup']).to include('let(:user) { create(:user) }')
        expect(patterns['setup']).not_to include('let(:name) { \'John\' }')
      end

      it 'limits setup patterns to MAX_PATTERNS_PER_CATEGORY' do
        create_test_file('spec/features/test_spec.rb', <<~RUBY)
          RSpec.describe 'Test' do
            let(:user) { create(:user) }
            let(:project) { create(:project) }
            let(:issue) { create(:issue) }
            let(:merge_request) { create(:merge_request) }
            let(:note) { create(:note) }

            it 'does something' do
              # test code
            end
          end
        RUBY

        patterns = extractor.extract_patterns(['spec/features/test_spec.rb'])

        expect(patterns['setup'].size).to eq(described_class::MAX_PATTERNS_PER_CATEGORY)
      end
    end

    context 'with navigation patterns' do
      it 'extracts visit calls' do
        create_test_file('spec/features/test_spec.rb', <<~RUBY)
          RSpec.describe 'Test' do
            it 'visits project page' do
              visit project_path(project)
              visit edit_project_path(project)
            end
          end
        RUBY

        patterns = extractor.extract_patterns(['spec/features/test_spec.rb'])

        expect(patterns['navigation']).to include('visit project_path(project)')
        expect(patterns['navigation']).to include('visit edit_project_path(project)')
      end

      it 'truncates long visit calls' do
        create_test_file('spec/features/test_spec.rb', <<~RUBY)
          RSpec.describe 'Test' do
            it 'visits page' do
              visit very_long_path_with_many_parameters(param1: 'value1', param2: 'value2', param3: 'value3')
            end
          end
        RUBY

        patterns = extractor.extract_patterns(['spec/features/test_spec.rb'])

        expect(patterns['navigation'].first.length).to be <= described_class::MAX_LINE_LENGTH
        expect(patterns['navigation'].first).to end_with('...')
      end

      it 'excludes visit calls inside expect blocks' do
        create_test_file('spec/features/test_spec.rb', <<~RUBY)
          RSpec.describe 'Test' do
            it 'visits page' do
              visit project_path(project)

              expect { visit other_path }.to change { something }
            end
          end
        RUBY

        patterns = extractor.extract_patterns(['spec/features/test_spec.rb'])

        expect(patterns['navigation']).to include('visit project_path(project)')
        expect(patterns['navigation'].size).to eq(1)
      end
    end

    context 'with interaction patterns' do
      it 'extracts fill_in calls' do
        create_test_file('spec/features/test_spec.rb', <<~RUBY)
          RSpec.describe 'Test' do
            it 'fills in form' do
              fill_in 'Name', with: 'John Doe'
              fill_in 'Email', with: 'john@example.com'
            end
          end
        RUBY

        patterns = extractor.extract_patterns(['spec/features/test_spec.rb'])

        expect(patterns['interaction']).to include("fill_in 'Name', with: 'John Doe'")
        expect(patterns['interaction']).to include("fill_in 'Email', with: 'john@example.com'")
      end

      it 'extracts click_button calls' do
        create_test_file('spec/features/test_spec.rb', <<~RUBY)
          RSpec.describe 'Test' do
            it 'clicks buttons' do
              click_button 'Submit'
              click_button 'Cancel'
            end
          end
        RUBY

        patterns = extractor.extract_patterns(['spec/features/test_spec.rb'])

        expect(patterns['interaction']).to include("click_button 'Submit'")
        expect(patterns['interaction']).to include("click_button 'Cancel'")
      end

      it 'extracts click_link calls' do
        create_test_file('spec/features/test_spec.rb', <<~RUBY)
          RSpec.describe 'Test' do
            it 'clicks links' do
              click_link 'Home'
              click_link 'Settings'
            end
          end
        RUBY

        patterns = extractor.extract_patterns(['spec/features/test_spec.rb'])

        expect(patterns['interaction']).to include("click_link 'Home'")
        expect(patterns['interaction']).to include("click_link 'Settings'")
      end

      it 'extracts select_listbox_item calls' do
        create_test_file('spec/features/test_spec.rb', <<~RUBY)
          RSpec.describe 'Test' do
            it 'selects items' do
              select_listbox_item('Option 1')
              select_listbox_item('Option 2')
            end
          end
        RUBY

        patterns = extractor.extract_patterns(['spec/features/test_spec.rb'])

        expect(patterns['interaction']).to include("select_listbox_item('Option 1')")
        expect(patterns['interaction']).to include("select_listbox_item('Option 2')")
      end

      it 'extracts within_testid blocks with first action' do
        create_test_file('spec/features/test_spec.rb', <<~RUBY)
          RSpec.describe 'Test' do
            it 'interacts within testid' do
              within_testid('modal') do
                click_button 'Confirm'
                fill_in 'Name', with: 'Test'
              end
            end
          end
        RUBY

        patterns = extractor.extract_patterns(['spec/features/test_spec.rb'])

        expect(patterns['interaction']).to include(
          "within_testid('modal') do\n      click_button 'Confirm'\nend"
        )
      end

      it 'skips expects in within_testid blocks' do
        create_test_file('spec/features/test_spec.rb', <<~RUBY)
          RSpec.describe 'Test' do
            it 'interacts within testid' do
              within_testid('modal') do
                expect(page).to have_content('Title')
                click_button 'Confirm'
              end
            end
          end
        RUBY

        patterns = extractor.extract_patterns(['spec/features/test_spec.rb'])

        expect(patterns['interaction']).to include(
          "within_testid('modal') do\n      click_button 'Confirm'\nend"
        )
      end

      it 'excludes interactions inside expect blocks' do
        create_test_file('spec/features/test_spec.rb', <<~RUBY)
          RSpec.describe 'Test' do
            it 'interacts' do
              click_button 'Submit'

              expect { click_button 'Delete' }.to change { count }
            end
          end
        RUBY

        patterns = extractor.extract_patterns(['spec/features/test_spec.rb'])

        expect(patterns['interaction']).to include("click_button 'Submit'")
        expect(patterns['interaction'].size).to eq(1)
      end

      it 'excludes interactions inside aggregate_failures blocks' do
        create_test_file('spec/features/test_spec.rb', <<~RUBY)
          RSpec.describe 'Test' do
            it 'interacts' do
              click_button 'Submit'

              aggregate_failures do
                click_button 'Verify'
                expect(page).to have_content('Success')
              end
            end
          end
        RUBY

        patterns = extractor.extract_patterns(['spec/features/test_spec.rb'])

        expect(patterns['interaction']).to include("click_button 'Submit'")
        expect(patterns['interaction'].size).to eq(1)
      end
    end

    context 'with file errors' do
      it 'warns and skips files that cannot be read' do
        file_path = 'spec/features/test_spec.rb'
        full_path = File.join(gitlab_root, file_path)
        FileUtils.mkdir_p(File.dirname(full_path))
        FileUtils.touch(full_path)

        allow(File).to receive(:read).with(full_path).and_raise(Errno::EACCES)

        expect do
          extractor.extract_patterns([file_path])
        end.to output(/Warning: Could not read/).to_stderr
      end

      it 'skips non-existent files' do
        patterns = extractor.extract_patterns(['spec/features/nonexistent_spec.rb'])

        expect(patterns['setup']).to be_empty
        expect(patterns['navigation']).to be_empty
        expect(patterns['interaction']).to be_empty
      end
    end

    context 'with multiple files' do
      it 'combines patterns from multiple files' do
        create_test_file('spec/features/test1_spec.rb', <<~RUBY)
          RSpec.describe 'Test1' do
            let(:user) { create(:user) }

            it 'does something' do
              visit project_path(project)
            end
          end
        RUBY

        create_test_file('spec/features/test2_spec.rb', <<~RUBY)
          RSpec.describe 'Test2' do
            let(:project) { create(:project) }

            it 'does something else' do
              click_button 'Submit'
            end
          end
        RUBY

        patterns = extractor.extract_patterns([
          'spec/features/test1_spec.rb',
          'spec/features/test2_spec.rb'
        ])

        expect(patterns['setup']).to include('let(:user) { create(:user) }')
        expect(patterns['setup']).to include('let(:project) { create(:project) }')
        expect(patterns['navigation']).to include('visit project_path(project)')
        expect(patterns['interaction']).to include("click_button 'Submit'")
      end

      it 'removes duplicate patterns' do
        create_test_file('spec/features/test1_spec.rb', <<~RUBY)
          RSpec.describe 'Test1' do
            let(:user) { create(:user) }

            it 'does something' do
              visit project_path(project)
            end
          end
        RUBY

        create_test_file('spec/features/test2_spec.rb', <<~RUBY)
          RSpec.describe 'Test2' do
            let(:user) { create(:user) }

            it 'does something else' do
              visit project_path(project)
            end
          end
        RUBY

        patterns = extractor.extract_patterns([
          'spec/features/test1_spec.rb',
          'spec/features/test2_spec.rb'
        ])

        expect(patterns['setup'].count('let(:user) { create(:user) }')).to eq(1)
        expect(patterns['navigation'].count('visit project_path(project)')).to eq(1)
      end
    end

    context 'with invalid Ruby syntax' do
      it 'skips files with syntax errors' do
        create_test_file('spec/features/test_spec.rb', <<~RUBY)
          RSpec.describe 'Test' do
            let(:user) { create(:user)
            # Missing closing brace
        RUBY

        patterns = extractor.extract_patterns(['spec/features/test_spec.rb'])

        expect(patterns['setup']).to be_empty
        expect(patterns['navigation']).to be_empty
        expect(patterns['interaction']).to be_empty
      end
    end
  end

  def create_test_file(path, content)
    full_path = File.join(gitlab_root, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end
end
