#!/usr/bin/env ruby -w

require 'rubygems'
require 'bundler/setup'
require 'thor'
require 'logger'
require 'json'

$log = nil

def read_recipes(file)
  JSON.load_file(file, symbolize_names: true).to_h { |r| [r[:name], r] }
end

def dependencies(recipes, output, count, inputs)
  $log.debug "Start #{output}"
  if inputs.is_a? Array
    inputs = inputs.to_h { |i| [i, 0] }
  else
    inputs = inputs.dup
  end
  return {}, { output => count } if inputs[output]
  recipe = recipes[output]
  raise "no recipe for #{output}!" if recipe.nil?
  $log.debug "Recipe #{output}: #{recipe}"
  build = { build: output, amount: count }
  build[:recipe] = recipe[:ingredients].to_h { |i| [i[:name], i[:amount]] }
  build[:recipe][:time] = recipe[:energy]
  builds = [build]

  product = recipe[:products].find { |p| p[:name] = output }
  raise "no product for #{output}!" if product.nil?
  raise "proability not 1 for #{output}" if product[:probability] != 1
  $log.debug "Product #{output}: #{product}"
  build[:recipe][:amount] = product[:amount]
  count /= product[:amount].to_f

  build[:machines] = recipe[:energy] * count

  ingredients = recipe[:ingredients]
    .map { |i| { name: i[:name], amount: i[:amount] * count } }
  $log.debug "Ingredients #{output}: #{ingredients}"

  ingredients.reject! do |i|
    if inputs[i[:name]]
      inputs[i[:name]] += i[:amount]
      true
    else
      false
    end
  end

  nested = ingredients.map do |i|
    dependencies recipes, i[:name], i[:amount], inputs.keys
  end
  nested.each do |nested_ingredients, nested_inputs|
    builds = nested_ingredients + builds
    inputs = inputs.merge(nested_inputs) do |k, a, b|
      a + b
    end
  end

  $log.info "Finish #{output}, nested: #{ingredients}, inputs: #{inputs}"
  return builds, inputs
end

def optimize(plan)
  has_capacity = {}
  plan.reject do |step|
    next unless step[:machines] < 1
    build = step[:build]
    h = has_capacity[build]
    if h.nil?
      has_capacity[build] = step
      next
    end
    if h[:machines] + step[:machines] <= 1
      h[:amount] += step[:amount]
      h[:machines] += step[:machines]
      $log.info "merging steps for #{step[:build]}"
      next true
    end
    if step[:machines] < h[:machines]
      has_capcity[build] = step[:machines]
    end
    false
  end
end

class PlanCLI < Thor
  class_option :recipes_file, default: 'recipes.json'

  class_option :verbose, :type => :boolean, :aliases => "-v"
  class_option :debug, :type => :boolean, :aliases => "-d"
  class_option :quiet, :type => :boolean, :aliases => "-q"
  def initialize(*)
    super
    $log = Logger.new(STDOUT)

    if options[:debug]
      $log.level = Logger::DEBUG
      $log.info("Logger level set to DEBUG")
    elsif options[:verbose]
      $log.level = Logger::INFO
      $log.info("Logger level set to INFO")
    elsif options[:quiet]
      $log.level = Logger::ERROR
      $log.info("Logger level set to ERROR")
    else
      $log.level = Logger::WARN
      $log.info("Logger level defaulting to WARN")
    end
  end

  desc 'recipe', 'print recipe for single item'
  def recipe(item)
    puts recipes[item]
  end

  desc 'all-items', 'print all items'
  def all_items
    puts recipes.keys
  end

  desc 'line', 'plan a line to build an item at a certain count per second'
  def line(item, rate=1)
    plan, input =  dependencies recipes, item, rate.to_f, %w[iron-plate copper-plate coal stone-brick steel-plate]
    puts optimize(plan), input
  end

  desc 'test', 'dev test'
  def test
    $log.debug 'Start Test'
    plan, input =  dependencies recipes, 'logistic-science-pack', 1, %w[iron-plate copper-plate]
    puts optimize(plan), input
    # puts recipes['logistic-science-pack']
    # puts recipes['electronic-circuit']
    # puts recipes.keys.sort
  end

  no_commands do
    def recipes
      read_recipes options[:recipes_file]
    end
  end
end

PlanCLI.start(ARGV)
