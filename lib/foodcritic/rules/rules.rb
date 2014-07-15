require 'yaml' # included in ruby

rule 'RACK001', 'Missing "# Copyright" declaration' do
  tags %w(style rackspace)
  cookbook do |path|
    matches = []

    recipes = Dir["#{path}/{#{standard_cookbook_subdirs.join(',')}}/**/*.rb"]
    recipes += Dir["#{path}/*.rb"]
    recipes.collect do |recipe|

      # skip things without 'recipes' in the path
      next if !recipe.include? '/recipes/'

      # need to scan comments for this rule
      lines = File.readlines(recipe)
      next if lines.collect do |line|
        line.include?('# Copyright')
      end.compact.flatten.include? true

      matches << {
        :filename => recipe,
        :matched => recipe,
        :line => 0,
        :column => 0
      }
    end # recipe

    matches
  end # cookbook
end # rule

rule 'RACK002', 'Recipe contains a single include_recipe' do
  tags %w(style rackspace)
  cookbook do |path|
    matches = []

    recipes = Dir["#{path}/{#{standard_cookbook_subdirs.join(',')}}/**/*.rb"]
    recipes += Dir["#{path}/*.rb"]
    recipes.collect do |recipe|

      # skip things without 'recipes' in the path
      next if !recipe.include? '/recipes/'

      # unfortunately, we need to scan source for this rule
      # as the AST of a recipe could span multiple files
      lines = File.readlines(recipe)
      non_comments = lines.collect do |line|
        next if line.nil?
        next if line.strip.nil?
        next if line.strip.start_with? '#'
        next if line.strip == ""
        line.strip
      end.compact

      next if non_comments.length != 1
      next if !non_comments.first.start_with? "include_recipe"

      matches << {
        :filename => recipe,
        :matched => recipe,
        :line => 0,
        :column => 0
      }
    end # recipe

    matches
  end # cookbook
end # rule

rule 'RACK003', 'Cookbook is missing a standard file' do
  tags %w(style rackspace)

  expected_files = %w(README.md metadata.rb LICENSE Gemfile Berksfile Rakefile Thorfile Guardfile .kitchen.yml .rubocop.yml )

  cookbook do |path|
    matches = []
    expected_files.each do |f|
      next unless !File.exist?("#{path}/#{f}")

      matches << {
          :filename => "#{f}",
          :matched => 'missing',
          :line => 0,
          :column => 0
      }
    end
    matches
  end # cookbook
end # rule

rule 'RACK004', 'Cookbook is missing a default test suite' do
  tags %w(style rackspace)

  search_files = %w( .kitchen.yml .kitchen.local.yml )
  default_suite_found = false

  cookbook do |path|
    matches = []

    search_files.each do |f|
      next unless File.exist?("#{path}/#{f}")

      kitchen_config = YAML.load_file("#{path}/#{f}")

      next if !kitchen_config.has_key?('suites')

      kitchen_config['suites'].each do |test_suite|
        next unless test_suite.has_key?('name')
        default_suite_found = true if test_suite['name'] == 'default'
      end
    end

    if !default_suite_found
      matches << {
          :filename => ".kitchen.local.yml",
          :matched => 'missing default test suite',
          :line => 0,
          :column => 0
      }
    end

    matches
  end # cookbook
end # rule
