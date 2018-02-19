# Onde

Onde ('OWN-jee') is a simple Ruby gem for referencing file and directory paths meaningfully.

Scripts that need to know the location of more than a few files often become confusing to maintain because file and directory paths are generated haphazardly in various parts of the code.

Onde fixes that by allowing you to attach meaningful names to your significant files and directories.


## Usage
To use Onde, create a YAML file named `onde.yml` in the root directory of your project. The file that maps important files and directories to convenient aliases that you can use to refer to those files.


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
    - 
      - 
        
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


## License
Onde is maintained by Aaron Knight (<iamaaronknight@gmail.com>).  It is released
under the MIT license. See the LICENSE file for more details.

