#!/usr/bin/env ruby -w

require 'rubygems'
require 'bundler/setup'
require 'thor'
require 'json'

def read_recipies(file)
  JSON.load_file(file, symbolize_names: true).to_h { |r| [r[:name], r] }
end

def dependencies(recipes, output, count, inputs)
  return { output => count } if inputs.include? output
  recipe = recipes[output]
  return {} if recipe.nil?
  ingredients = recipe[:ingredients].to_h { |i| [i[:name], i[:amount]] }
  nested = ingredients.map do |name, amount|
    dependencies recipes, name, amount * count, inputs
  end
  nested.each do |n|
    ingredients.merge!(n) do |k, a, b|
      a + b
    end
  end
  ingredients
end

class PlanCLI < Thor
  desc 'test', 'dev test'
  def test
    puts 'Start Test'
    recipes = read_recipies 'recipes.json'
    puts dependencies recipes, 'logistic-science-pack', 1, %w[iron-plate copper-plate]
    # puts recipes['logistic-science-pack']
    # puts recipes['electronic-circuit']
    # puts recipes.keys.sort
  end
end

PlanCLI.start(ARGV)
