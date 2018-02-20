# Onde

Onde ('OWN-jee') is a simple Ruby gem for referencing file and directory paths meaningfully.

Scripts that need to know the location of more than a few files often become confusing to maintain because file and directory paths are generated haphazardly in various parts of the code.

Onde fixes that by allowing you to attach meaningful names to your significant files and directories.


## Quickstart
Install Onde:

`gem install onde`

To use Onde, create a YAML file named `.onde.yml` in the root directory of your project. The file that maps important files and directories to convenient aliases that you can use to refer to those files.


**paths.yml**
```yaml
-
  - some_alias: some_path/some_file.txt
```

You can then retrieve the aliased path with `Onde.path(alias)`:

```ruby
> Onde.aliases
 => #<Set: {"some_alias"}>
> Onde.paths
 => {"some_alias"=>"some_path/some_file.txt"}
> Onde.path('some_alias')
 => "some_path/some_file.txt"
```

Paths can include variables, which are marked with angle brackets. When calling `paths()` you can fill in the variables:

**paths.yml**
```yaml
- 
  - my_alias: /<my_directory>/<my_file>.txt
```

```ruby
> Onde.aliases
 => #<Set: {"my_alias"}>
> Onde.paths
 => {"my_alias"=>"/<my_directory>/<my_file>.txt"}
> Onde.path('my_alias', my_directory: 'hey_there', my_file: 'hows_it_going')
=> "/hey_there/hows_it_going.txt"
```

Directories can be nested, to make it easy to refer to represent multiple significant locations within a file system.

**paths.yml**
```yaml
-
  - top_level: some/folder/
  - 
    - 
      - path/to/
      - 
        -
          - thing1: child/
        -
          - child2/
          -
            -
              - thing2: deeply/embedded/thing.txt
        
```

```ruby
> Onde.aliases
 => #<Set: {"top_level", "thing1", "thing2"}>
> Onde.path('top_level')
 => "some/folder"
> Onde.path('thing1')
 => "some/folder/path/to/child/"
> Onde.path('thing2')
 => "some/folder/path/to/child2/deeply/embedded/thing.txt"
```


## Usage

### The paths file
The default name and location for your paths file is `./.onde.yml`. You can also set a different file name or location:

```ruby
> Onde.onde_file_path = 'example.yaml'
 => "example.yaml"
```

A well-formed Onde paths file should be in the format:
```yaml
-                                    # The yaml file is composed of one or more nodes
  - path_segment                     # Each node contains at least one item, which represents the file path
  -                                  # Nodes can also contain a second list item for any children.
    -                                # This represents the root of another node.
      - alias: path_segment          # This is how to attach an alias to a particular path.
    -                                # Here's a sibling node, representing another file in the same directory
      - alias2: <variable>.txt       # Declare variables in angle brackets.
```

Errors in configuring your paths file will raise an `Onde::ConfigurationError`.

### The .aliases class method
You can list all of the available aliases by calling `.aliases`. The return value is a set of symbols.

```ruby
> Onde.aliases
 => #<Set: {:audio_files_dir, :album_art, :description, :songs_directory, :mp3, :wav}>
```

### The .paths class method
You can list all of the paths loaded from your paths yaml file by calling `.paths`. The return value is a hash of aliases mapped to their respective paths. 

```ruby
> Onde.paths
 => {:audio_files_dir=>"~/Desktop/AudioFiles", :album_art=>"~/Desktop/AudioFiles/<artist_name>/<album_name>.png", :description=>"~/Desktop/AudioFiles/<artist_name>/<album_name>.txt", :songs_directory=>"~/Desktop/AudioFiles/<artist_name>/songs/", :mp3=>"~/Desktop/AudioFiles/<artist_name>/songs/<song_name>.mp3", :wav=>"~/Desktop/AudioFiles/<artist_name>/songs/<song_name>.wav"}
```

Note that the paths are listed "raw": spaces are not escaped, path variables are not filled in, the home directory is not expanded, terminal slashes are not applied for directories, etc.

### The .path class method
The `.path` method returns the full path for a specific alias:

```ruby
> Onde.path(:audio_files_dir)
 => "/Users/myuser/Desktop/AudioFiles"
```

By default,
- The `~` symbol at the start of a path is expanded to the current user's home directory.
- A terminal slash is not added for a path that represents a directory.
- Spaces in the file path are escaped.

The `.path` method takes a second argument which is a hash containing path variables. Each key in the hash should match a variable name, and the value is the string which will be substituted for that variable.

```ruby
> Onde.path(:album_art, artist_name: 'Deltron 3030', album_name: 'Deltron 3030')
 => "/Users/myuser/Desktop/AudioFiles/Deltron\\ 3030/Deltron\\ 3030.png"
```

If you fail to supply a value for a variable present in the path, the method will raise an `Onde::ArgumentsError`. If you supply extra elements in the hash, those keys and values will be ignored.

Extra options can be supplied in a third argument to `.paths`:
```ruby
> Onde.path(:album_art, {artist_name: 'Deltron 3030', album_name: 'Deltron 3030'}, {escape_spaces: false, expand_home_dir: false})
 => "~/Desktop/AudioFiles/Deltron 3030/Deltron 3030.png"
```

Options:
- `:expand_home_dir`: (default: `true`) When set to `false`, a `~` symbol at the start of a path will not be expanded to the user's home directory.
- `:escape_spaces`: (default: `true`) When set to `false`, spaces in a path name are left as-is and not escaped.
- `:terminal_slash`: (default: `false`) When set to `true`, ensures that the path ends with a final `/`. Note that this will append a final slash, regardless of whether the path represents a file or directory.


## License
Onde is maintained by Aaron Knight (<iamaaronknight@gmail.com>).  It is released
under the MIT license. See the LICENSE file for more details.


## Contributing
Contributions are welcome. To contribute:
- Fork this repository
- Read through this README and propose changes if you find anything that's confusing, inacurrate, or that could simply be explained better.
- Check [open issues](https://github.com/iamaaronknight/onde/issues) or add a new issue if you have a problem or something you'd like to add.
- Write some code
- Run tests: `rspec spec/`
- Create a pull request
- Wait (but I'll try not to make you wait too long)
