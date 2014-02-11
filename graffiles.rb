#
# Script to generate a branch diagram in OmniGraffle

# Gems
require 'rubygems'
require 'FileUtils'

# Helpers
require 'osas_draws'

if ARGV.empty?
  puts "usage: $0 path/to/rails_app"
  puts " "
else 
  commits   = ARGV.join(',').scan(/--commits=[0-9]*/).first.split('=')[1] rescue 20
  base_node = ARGV.join(',').scan(/--base=[a-zA-Z0-9_.-]*/).first.split('=')[1] rescue 'master'

  # Substitute the path to your repo (or send me a patch to make this accept args)
  rails_root = Dir.open File.expand_path( ARGV[0].presence || '.')
  tree = get_app_tree

  commits = repo.commits( base_node, commits ) # second parameter is number of commits to use
  shapes = {} # Shapes holds a hash of the commit id against the applescript reference to its graphic

  puts "\n# Create graphics for each file "
  commits.each do |c|
   shapes[c.id] = make_graphic_for_commit(c)
   puts "- " + shapes[c.id]
  end

  "# For each commit, iterate its parents then draw lines "
  commits.each do |c|
    c.parents.each do |p|
      if shapes.has_key? p.id then
        make_line_between_graphics(shapes[c.id], shapes[p.id])
      end
    end
  end

  puts "# Create graphics for all the tags   "
  repo.tags.each do |t|
      if shapes.has_key? t.commit.id then #if we didn't draw the commit, don't draw the tag that refs it.
        tagGraphic = make_graphic_for_tag(t)
        make_line_between_graphics(tagGraphic, shapes[t.commit.id])
      end
  end
    
  puts "# Create graphics for the heads "
  repo.heads.each do |h|
    if shapes.has_key? h.commit.id then
      headGraphic = make_graphic_for_head(h)
      make_line_between_graphics(headGraphic, shapes[h.commit.id])
    end
  end
    
  puts "# Tidy up "
    layout()

  puts "Done!"
end

def get_app_tree dir_only = false
  Dir.glob('**/*'). # get all files below current dir
    select{|f|
      dir_only ? File.directory?(f) : true
    }.map{|path|
      path.split '/' # split to parts
    }.inject({}){|acc, path| # start with empty hash
      path.inject(acc) do |acc2,dir| # for each path part, create a child of current node
        acc2[dir] ||= {} # and pass it as new current node
      end
      acc
    }
end
