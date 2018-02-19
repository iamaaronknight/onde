require 'yaml'
require 'set'


class Onde
  class ArgumentsError < StandardError; end
  class ConfigurationError < StandardError; end

  class << self
    def onde_file_path=(path)
      begin
        YAML.load_file(path)
      rescue Errno::ENOENT
        raise Onde::ConfigurationError.new('No .yml file found at the specified path')
      end
      @@onde_file_path = path
    end

    def onde_file_path
      @@onde_file_path ||= '.onde.yml'
    end

    def path(path_alias, variables={}, options={})
      _path = paths[path_alias.to_sym]

      if variables
        variables.each do |variable, value|
          _path = _path.gsub(/<#{variable}>/, value.to_s)
        end
      end

      if !!(_path =~ /<.*?>/)
        raise Onde::ArgumentsError.new("No value supplied for the variable #{ _path.scan(/<.*?>/)[0] }")
      end

      escape_spaces = options[:escape_spaces]
      escape_spaces = true if escape_spaces.nil?
      _path = _path.gsub(/ /, '\ ') if escape_spaces

      terminal_slash = options[:terminal_slash]
      terminal_slash = false if terminal_slash.nil?
      _path = _path + '/' if terminal_slash and !(_path =~ /\/\z/)

      expand_home = options[:expand_home_dir]
      expand_home = true if expand_home.nil?
      _path = _path.sub(/\A~/, Dir.home) if expand_home

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
    if node.alias
      node_alias = node.alias.to_sym
      if @expanded_paths[node_alias]
        raise Onde::ConfigurationError.new('More than one path is tagged with the same alias.') 
      end
      @expanded_paths[node_alias] = node.path
    end

    node.children.each do |child_node|
      expand_node(child_node)
    end
  end
end


class Onde::Node
  attr_reader :alias, :path, :children

  def initialize(data, parent_path=nil)
    unless data.is_a? Array
      raise Onde::ConfigurationError.new("Node #{data} is not properly formed")
    end
    node_data, child_data = data
    if node_data.is_a? Hash
      @alias = node_data.keys()[0]
      path_part = node_data[@alias]
    elsif node_data.is_a? String
      @alias = nil
      path_part = node_data
    else
      raise Onde::ConfigurationError.new("Node #{data} is not properly formed")
    end
    
    @path = parent_path.nil? ? path_part : File.join(parent_path, path_part)
    
    child_data ||= []
    @children = child_data.map do |child_data|
      Onde::Node.new(child_data, @path)
    end
  end
end
