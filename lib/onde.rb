require 'yaml'
require 'set'

class Onde
  class << self
    def onde_file_path=(path)
      @@onde_file_path = path
    end

    def onde_file_path
      @@onde_file_path ||= '.onde.yml'
    end

    def path(path_alias)
      paths[path_alias]
    end

    def aliases
      Set.new(paths.keys)
    end

    def paths
      @@expanded_paths ||=  get_paths
    end
    
    private def get_paths
      raw_data = YAML.load_file(onde_file_path)
      Onde::DirectoryStructure.paths(raw_data)
    end
  end
end


class Onde::DirectoryStructure
  def self.paths(data)
    self.new(data).to_hash
  end

  def initialize(data)
    @expanded_paths = {}
    data.map do |node_data|
      node = Onde::Node.new(node_data)
      expand_node(node)
    end
  end

  def to_hash
    @expanded_paths
  end

  private def expand_node(node)
    @expanded_paths[node.alias] = node.path if node.alias
    node.children.each do |child_node|
      expand_node(child_node)
    end
  end
end


class Onde::Node
  attr_reader :alias, :path, :children

  def initialize(data, parent_path=nil)
    node_data, child_data = data
    if node_data.is_a? Hash
      @alias = node_data.keys()[0]
      path_part = node_data[@alias]
    else
      @alias = nil
      path_part = node_data
    end
    @path = parent_path.nil? ? path_part : File.join(parent_path, path_part)
    
    child_data ||= []
    @children = child_data.map do |child_data|
      Onde::Node.new(child_data, @path)
    end
  end
end
