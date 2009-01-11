require 'rubygems'
require 'graphviz'

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

  begin
    g.output(:file => 'temp.dot', :output => 'dot')
    system "tred temp.dot|dot -Tpng > #{gem_name}.png"
  ensure
    File.delete('temp.dot')
  end
end
