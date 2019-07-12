# frozen_string_literal: true
require 'spec_helper'

describe SortingHelper do
  include ApplicationHelper
  include IconsHelper
  include ExploreHelper

  def set_sorting_url(option)
    allow(self).to receive(:request).and_return(double(path: 'http://test.com', query_parameters: { label_name: option }))
  end

  describe '#issuable_sort_option_title' do
    it 'returns correct title for issuable_sort_option_overrides key' do
      expect(issuable_sort_option_title('created_asc')).to eq('Created date')
    end

    it 'returns correct title for a valid sort value' do
      expect(issuable_sort_option_title('priority')).to eq('Priority')
    end

    it 'returns nil for invalid sort value' do
      expect(issuable_sort_option_title('invalid_key')).to eq(nil)
    end
  end

  describe '#issuable_sort_direction_button' do
    before do
      set_sorting_url 'test_label'
    end

    it 'keeps label filter param' do
      expect(issuable_sort_direction_button('created_date')).to include('label_name=test_label')
    end

    it 'returns icon with sort-highest when sort is created_date' do
      expect(issuable_sort_direction_button('created_date')).to include('sort-highest')
    end

    it 'returns icon with sort-lowest when sort is asc' do
      expect(issuable_sort_direction_button('created_asc')).to include('sort-lowest')
    end

    it 'returns icon with sort-lowest when sorting by milestone' do
      expect(issuable_sort_direction_button('milestone')).to include('sort-lowest')
    end

    it 'returns icon with sort-lowest when sorting by due_date' do
      expect(issuable_sort_direction_button('due_date')).to include('sort-lowest')
    end
  end

  def stub_controller_path(value)
    allow(helper.controller).to receive(:controller_path).and_return(value)
  end

  def project_common_options
    {
      sort_value_latest_activity  => sort_title_latest_activity,
      sort_value_recently_created => sort_title_created_date,
      sort_value_name             => sort_title_name,
      sort_value_stars_desc       => sort_title_stars
    }
  end

  describe 'with `admin/projects` controller' do
    before do
      stub_controller_path 'admin/projects'
    end

    describe '#projects_sort_options_hash' do
      it 'returns a hash of available sorting options' do
        admin_options = project_common_options.merge({
          sort_value_oldest_activity  => sort_title_oldest_activity,
          sort_value_oldest_created   => sort_title_oldest_created,
          sort_value_recently_created => sort_title_recently_created,
          sort_value_stars_desc       => sort_title_most_stars,
          sort_value_largest_repo     => sort_title_largest_repo
        })

        expect(projects_sort_options_hash).to eq(admin_options)
      end
    end
  end

  describe 'with `projects` controller' do
    before do
      stub_controller_path 'projects'
    end

    describe '#projects_sort_options_hash' do
      it 'returns a hash of available sorting options' do
        expect(projects_sort_options_hash).to include(project_common_options)
      end
    end

    describe '#projects_reverse_sort_options_hash' do
      context 'returns a reversed hash of available sorting options' do
        using RSpec::Parameterized::TableSyntax

        where(:sort_key, :reverse_sort_title) do
          sort_value_latest_activity  | sort_value_oldest_activity
          sort_value_recently_created | sort_value_oldest_created
          sort_value_name             | sort_value_name_desc
          sort_value_stars_desc       | sort_value_stars_asc
          sort_value_oldest_activity  | sort_value_latest_activity
          sort_value_oldest_created   | sort_value_recently_created
          sort_value_name_desc        | sort_value_name
          sort_value_stars_asc        | sort_value_stars_desc
        end

        with_them do
          it do
            reverse_hash = projects_reverse_sort_options_hash

            expect(reverse_hash).to include(sort_key)
            expect(reverse_hash[sort_key]).to eq(reverse_sort_title)
          end
        end
      end
    end

    describe '#project_sort_direction_button' do
      context 'returns the correct icon for each sort option' do
        using RSpec::Parameterized::TableSyntax

        sort_lowest_icon = 'sort-lowest'
        sort_highest_icon = 'sort-highest'

        where(:selected_sort, :icon) do
          sort_value_latest_activity  | sort_highest_icon
          sort_value_recently_created | sort_highest_icon
          sort_value_name_desc        | sort_highest_icon
          sort_value_stars_desc       | sort_highest_icon
          sort_value_oldest_activity  | sort_lowest_icon
          sort_value_oldest_created   | sort_lowest_icon
          sort_value_name             | sort_lowest_icon
          sort_value_stars_asc        | sort_lowest_icon
        end

        with_them do
          it do
            set_sorting_url selected_sort

            expect(project_sort_direction_button(selected_sort)).to include(icon)
          end
        end
      end

      it 'returns the correct link to reverse the current sort option' do
        sort_options_links = projects_reverse_sort_options_hash

        sort_options_links.each do |selected_sort, reverse_sort|
          set_sorting_url selected_sort

          expect(project_sort_direction_button(selected_sort)).to include(reverse_sort)
        end
      end
    end

    describe '#projects_sort_option_titles' do
      it 'returns a hash of titles for the sorting options' do
        options = project_common_options.merge({
          sort_value_oldest_activity  => sort_title_latest_activity,
          sort_value_oldest_created   => sort_title_created_date,
          sort_value_name_desc        => sort_title_name,
          sort_value_stars_asc        => sort_title_stars
        })

        expect(projects_sort_option_titles).to eq(options)
      end
    end

    describe 'with project_list_filter_bar off' do
      before do
        stub_feature_flags(project_list_filter_bar: false)
      end

      describe '#projects_sort_options_hash' do
        it 'returns a hash of available sorting options' do
          options = project_common_options.merge({
            sort_value_oldest_activity  => sort_title_oldest_activity,
            sort_value_oldest_created   => sort_title_oldest_created,
            sort_value_recently_created => sort_title_recently_created,
            sort_value_stars_desc       => sort_title_most_stars
          })

          expect(projects_sort_options_hash).to eq(options)
        end
      end
    end
  end
end
