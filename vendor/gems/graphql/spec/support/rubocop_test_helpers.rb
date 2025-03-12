# frozen_string_literal: true

module RubocopTestHelpers
  def run_rubocop_on(fixture_path, autocorrect: false)
    assert_cop_runs_on(fixture_path)
    result = `bundle exec rubocop --debug #{autocorrect ? "--auto-correct" : ""} --config spec/fixtures/cop/.rubocop.yml #{fixture_path} 2>&1`
    refute_includes result, "An error occurred", "Nothing went wrong"
    result
  end

  def rubocop_errors(rubocop_result)
    rubocop_result =~ /(\d) offenses? detected/
    $1.to_i
  end

  def assert_rubocop_autocorrects_all(fixture_path)
    autocorrect_target_path = fixture_path.sub(".rb", "_autocorrect.rb")
    FileUtils.cp(fixture_path, autocorrect_target_path)
    run_rubocop_on(autocorrect_target_path, autocorrect: true)
    result2 = run_rubocop_on(autocorrect_target_path)
    assert_equal 0, rubocop_errors(result2), "All errors were corrected in #{autocorrect_target_path}:

    #{File.read(autocorrect_target_path)}

    ###

    #{result2}"
    expected_file = File.read(fixture_path.sub(".rb", "_corrected.rb"))
    assert_equal expected_file, File.read(autocorrect_target_path), "The autocorrected file has the expected contents"
  ensure
    FileUtils.rm(autocorrect_target_path)
  end

  def assert_cop_runs_on(fixture_path)
    @rubocop_config ||= YAML.load_file(File.expand_path("spec/fixtures/cop/.rubocop.yml"))
    file_name = fixture_path.split("/").last
    cop_name = "GraphQL/" + self.class.name.split("::").last
    cop_config = @rubocop_config[cop_name] || raise("No config for #{cop_name.inspect} (#{@rubocop_config.inspect})")
    assert cop_config["Enabled"], "#{cop_name} is enabled"
    if cop_config.key?("Include")
      assert cop_config["Include"].include?(file_name), "#{file_name.inspect} is included for #{cop_name}"
    end
  end
end
