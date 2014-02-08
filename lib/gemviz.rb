require 'rubygems'
require 'graphviz'
require 'tempfile'

VERSION = "0.2.2"

def build_dependencies_for(graph, gem_name)
  return if graph[gem_name]
  uses = `gem dep #{gem_name} --pipe`  
  uses = uses.split("\n").
      reject {|line| line =~ /Gem #{gem_name}/}.
      reject {|line| line =~ /No gems found/}.
      map {|gem| gem.split('--version')[0].strip} unless uses.nil?
  graph[gem_name] = uses
  uses.each {|gem| build_dependencies_for(graph, gem)}
end

ARGV.each do |gem_name|
  puts "creating ./#{gem_name}.png"
  graph = {}
  build_dependencies_for(graph, gem_name)  

  g = GraphViz::new( "G" )

  graph.each do |gem, dependent_gem| 
    gem_node = g.add_node(%Q/"#{gem}"/)
    dependent_gem.each do |dependent|
      dependent_node = g.add_node(%Q/"#{dependent}"/)
      g.add_edge(gem_node, dependent_node)
    end
  end

  Tempfile.open("gemviz-#{gem_name}") do |file|
    g.output(:dot => "#{file.path}")
    system "tred #{file.path} | dot -Tpng > #{gem_name}.png"
  end
end
