require 'yaml'
require 'set'


class Onde
  class ArgumentsError < StandardError; end

  class << self
    def onde_file_path=(path)
      @@onde_file_path = path
    end

    def onde_file_path
      @@onde_file_path ||= '.onde.yml'
    end

    def path(path_alias, kwargs={})
      _path = paths[path_alias]

      escape = kwargs.delete(:escape)
      escape = true if escape.nil?

      if kwargs
        kwargs.each do |variable, value|
          _path = _path.gsub(/<#{variable}>/, value)
        end
      end

      if !!(_path =~ /<.*?>/)
        raise Onde::ArgumentsError
      end

      _path = _path.gsub(/ /, '\ ') if escape

      _path
    end

    def aliases
      Set.new(paths.keys)
    end

    def paths
      @@expanded_paths ||=  Onde::DirectoryStructure.paths(YAML.load_file(onde_file_path))
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
