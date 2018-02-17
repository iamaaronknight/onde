require './lib/onde.rb'
require 'yaml'
require 'set'

describe 'Onde' do
  before :all do
    # Create a yaml file
    data = [
      {
        'nested' => [
          'test_directory', 
          {
            'bar' => ['bar.txt'],
          }
        ]
      }, 
      {
        'foo' => ['foo.txt']
      },
    ]
    File.open('./.test-onde.yml', 'w') {|file| file.write data.to_yaml }
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
    before :all do
      # Onde is a singleton so create it once for the test run with all of the paths
      Onde.onde_file_path = '.test-onde.yml'
    end

    it 'has the right onde file path' do
      expect(Onde.onde_file_path).to eq '.test-onde.yml'
    end

    describe '#aliases' do
      it 'returns all of the aliases' do
        expect(Onde.aliases).to eq Set.new(['nested', 'foo', 'bar'])
      end
    end

    describe '#paths' do
      it 'returns a hash of all the paths' do
        expect(Onde.paths).to eq (
          { 'nested' => 'test_directory',
            'foo' => 'foo.txt',
            'bar' => 'test_directory/bar.txt',
          }
        )
      end
    end

    describe '#path' do
      it 'returns a path' do
        expect(Onde.path('foo')).to eq 'foo.txt'
      end

      it 'returns a directory' do
        expect(Onde.path('nested')).to eq 'test_directory'
      end

      it 'returns a nested path' do
        expect(Onde.path('bar')).to eq 'test_directory/bar.txt'
      end
    end
  end
end
