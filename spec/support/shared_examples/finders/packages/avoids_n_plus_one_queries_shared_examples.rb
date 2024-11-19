# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'avoids N+1 database queries in the package registry' do |factory = :npm_package|
  it do
    control = ActiveRecord::QueryRecorder.new { finder.execute }

    create_list(factory, 2, project: project, name: package_name).each do |npm_package|
      ::Packages::DependencyLink.dependency_types.each_key do |dependency_type|
        create(:packages_dependency_link, package: npm_package, dependency_type: dependency_type)
      end
    end

    # query count can slightly change between the examples so we're using a custom threshold
    expect { finder.execute }.not_to exceed_query_limit(control).with_threshold(2)
  end
end
