require './lib/onde.rb'
require 'yaml'
require 'set'

YAML_CONTENTS = <<-eos
-
  - foo: foo.txt
-
  - test_directory/
  -
    -
      - bar: bar.txt
    -
      - deeply_nested: deep_test_directory/
      -
        -
          - baz: <file_name>.<file_type>
-
  - spacy: /A Folder/a file.txt
eos


describe Onde do
  before :all do
    # Create a yaml file
    File.open('./.test-onde.yml', 'w') {|file| file.write YAML_CONTENTS }
  end

  after :all do
    File.delete('./.test-onde.yml')
  end

  context 'with the onde file path not set' do
    it 'defaults to .onde.yaml' do
      expect(Onde.onde_file_path).to eq '.onde.yml'
    end
  end

  context 'with the onde file path explicitly set' do
    context 'to a non-existing file' do
      it 'raises an error' do
        expect{Onde.onde_file_path = '.non-existing.yml'}.to raise_error Onde::ConfigurationError
      end
    end

    context 'to an existing file' do
      before :all do
        # Onde is a singleton so create it once for the test run with all of the paths
        Onde.onde_file_path = '.test-onde.yml'
      end

      it 'has the right onde file path' do
        expect(Onde.onde_file_path).to eq '.test-onde.yml'
      end

      describe '#aliases' do
        it 'returns all of the aliases' do
          expect(Onde.aliases).to eq Set.new([:foo, :bar, :deeply_nested, :baz, :spacy])
        end
      end

      describe '#paths' do
        it 'returns a hash of all the paths' do
          expect(Onde.paths).to eq (
            { foo: 'foo.txt',
              bar: 'test_directory/bar.txt',
              deeply_nested: 'test_directory/deep_test_directory/',
              baz: 'test_directory/deep_test_directory/<file_name>.<file_type>',
              spacy: '/A Folder/a file.txt'
            }
          )
        end
      end

      describe '#path' do
        it 'returns a path' do
          expect(Onde.path(:foo)).to eq 'foo.txt'
        end

        it 'returns a directory' do
          expect(Onde.path(:deeply_nested)).to eq 'test_directory/deep_test_directory/'
        end

        it 'returns a nested path' do
          expect(Onde.path(:bar)).to eq 'test_directory/bar.txt'
        end

        context 'for a path with spaces in it' do
          it 'returns the path with spaces escaped' do
            expect(Onde.path(:spacy)).to eq '/A\ Folder/a\ file.txt'
          end

          it 'returns the path without spaces escaped when escaping is disabled' do
            expect(Onde.path(:spacy, escape: false)).to eq '/A Folder/a file.txt'
          end
        end

        context 'for an alias with variables' do
          it 'replaces the path variables with the specified values' do
            expect(Onde.path(:baz, file_name: 'test_file_name', file_type: 'txt')).to eq 'test_directory/deep_test_directory/test_file_name.txt'
          end

          it 'raises an error when values are not supplied for all of the variables' do
            expect{Onde.path(:baz, file_name: 'test_file_name')}.to raise_error Onde::ArgumentsError
          end
        end

        it 'works when passed a string instead of a symbol' do
          expect(Onde.path('foo')).to eq 'foo.txt'
        end
      end
    end
  end
end


describe Onde::DirectoryStructure do
  it 'initializes with valid data' do
    data = YAML.load(YAML_CONTENTS)
    onde = Onde::DirectoryStructure.new(data)
    expect(onde.to_hash).to eq (
      { foo: 'foo.txt',
        bar: 'test_directory/bar.txt',
        deeply_nested: 'test_directory/deep_test_directory/',
        baz: 'test_directory/deep_test_directory/<file_name>.<file_type>',
        spacy: '/A Folder/a file.txt'
      }
    )
  end

  it 'raises an error when the same alias is used more than once' do
    expect{Onde::DirectoryStructure.new([[{foo: 'path/a'}], [{foo: 'path/b'}]])}.to raise_error Onde::ConfigurationError
  end

  it 'raises an error for incorrectly formatted configuration data' do
    # These are some examples with well-formed data
    Onde::DirectoryStructure.new([[{foo: 'path/a'}]])
    Onde::DirectoryStructure.new([[{foo: 'path/a'}, [[{bar: 'path/b'}]]]])

    # - foo: path/a
    # instead of:
    # -
    #   - foo: path/a
    expect{
      Onde::DirectoryStructure.new([{foo: 'path/a'}])
    }.to raise_error Onde::ConfigurationError

    # -
    #   - foo: path/a
    #   -
    #     - bar: path/b
    # instead of :
    # -
    #   - foo: path/a
    #   -
    #     -
    #       - bar: path/b
    expect{
      Onde::DirectoryStructure.new([[{foo: 'path/a'}, [{bar: 'path/b'}]]])
    }.to raise_error Onde::ConfigurationError

    # -
    #   - foo: path/a
    #   - bar: path/b
    # instead of:
    # -
    #   - foo: path/a
    #   -
    #     -
    #       - bar: path/b
    # or:
    # -
    #   - foo: path/a
    # -
    #   - bar: path/b
    expect{
      Onde::DirectoryStructure.new([[{foo: 'path/a'}, {bar: 'path/b'}]])
    }.to raise_error Onde::ConfigurationError
  end
end