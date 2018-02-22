require 'yaml'
require 'set'


class Onde
  class ArgumentsError < StandardError; end
  class ConfigurationError < StandardError; end
  class PathError < StandardError; end

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
      raw_path = paths[path_alias.to_sym]
      raise Onde::PathError if not raw_path
      Onde::PathFormatter.new(raw_path, variables, options).get
    end

    def aliases
      Set.new(paths.keys)
    end

    def paths
      begin
        @@expanded_paths ||=  Onde::DirectoryStructure.paths(YAML.load_file(onde_file_path))
      rescue Errno::ENOENT
        raise Onde::ConfigurationError.new('No .yml file found at the specified path')
      end
    end

  end
end


class Onde::PathFormatter
  def initialize(raw_path, variables, options)
    @raw_path = raw_path
    @variables = variables
    @options = options
  end

  def get
    path = apply_variables(@raw_path) if @variables
    path = escape_spaces(path) if escape_spaces?
    path = add_terminal_slash(path) if terminal_slash?
    path = expand_home(path) if expand_home?
    path
  end

  private
    def apply_variables(path)
      @variables.each do |variable, value|
        path = path.gsub(/<#{variable}>/, value.to_s)
      end

      if !!(path =~ /<.*?>/)
        raise Onde::ArgumentsError.new("No value supplied for the variable #{ path.scan(/<.*?>/)[0] }")
      end

      path
    end

    def escape_spaces?
      @options[:escape_spaces].nil? ? true : @options[:escape_spaces]
    end

    def escape_spaces(path)
      path.gsub(/ /, '\ ')
    end

    def terminal_slash?
      @options[:terminal_slash].nil? ? false : @options[:terminal_slash]
    end

    def add_terminal_slash(path)
      !!(path =~ /\/\z/) ? path : path + '/'
    end

    def expand_home?
      @options[:expand_home_dir].nil? ? true: @options[:expand_home_dir]
    end

    def expand_home(path)
      path.sub(/\A~/, Dir.home)
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
