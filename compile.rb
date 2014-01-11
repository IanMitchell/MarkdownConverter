require 'html/pipeline'
require 'fileutils'

# Colors
class String
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end
end

# Translates links from .md to .html
class ConvertLinkFilter < HTML::Pipeline::Filter
  def call
    doc.search('a').each do |link|
      next if link['href'].nil?

      href = link['href'].strip
      unless href.start_with? '#'
        html = link['href'].dup
        html.slice! File.extname(html)
        html << '.html'
        html.slice!(0) if html[0] == '/'

        link['href'] = html
      end
    end
    doc
  end
end


# Checks all links to see if any are broken
def check_all_file_links_in_directory
  check = 0
  reg = /\[(?<text>[^\]]+)\]\((?<url>[^)]+)\)*/

  Dir.glob('*.md').each do |file|
    f = File.open(file, 'rb')
    contents = f.read
    file_list = contents.scan(reg).flatten.map { |capture| capture }
    file_list.each_index do |idx|
      unless idx % 2 == 0
        file_list[idx].slice!(0) if file_list[idx][0] == '/'
        unless File::exist? file_list[idx].to_s || file_list[idx][0] == '#'
          puts "\tThere is a broken link in #{file}: ".red + "\"#{file_list[idx]}\"".yellow
          check = 1
        end
      end
    end
    f.close
  end

  check
end

# Compiles all markdown files
def compile_all_markdown_files(pipeline)
  Dir.glob('*.md').each do |file|
    f = File.open(file, 'rb')
    contents = f.read
    result = pipeline.call contents

    html = file.dup
    html.slice! File.extname(html)
    html << '.html'

    File.open(html, 'w') do |f|
      f.puts result[:output].to_s
    end

    f.close
    File.delete file
  end
end



basedir = File.expand_path(File.dirname(__FILE__))
check = 0

# Check for valid links in all MD files
puts 'Checking for invalid links...'
Dir.chdir('src')
check = check + check_all_file_links_in_directory

Dir.glob('**/*/').each do |dir|
  puts "Changing to #{dir.to_s}..."
  Dir.chdir(basedir + '/src')
  Dir.chdir(dir)

  check = check + check_all_file_links_in_directory
end

puts 'Done!'.green
puts ''


# If any broken links, check to see if we still want to compile
while check
  print 'There were errors when checking the links; continue anyways? (y/n) '
  response = gets

  response.chomp!
  if response == 'n' || response == 'no'
    exit
  elsif response == 'y' || response == 'yes'
    check = false
  end
end


# If we get here, compile
pipeline = HTML::Pipeline.new [
  HTML::Pipeline::MarkdownFilter,
  ConvertLinkFilter
]

# Delete `/doc/` since we're going to be creating it
Dir.chdir(basedir)
FileUtils.rm_rf 'doc'

# Copy everything over
FileUtils.copy_entry 'src', 'doc'


# Compile
Dir.chdir('doc')
compile_all_markdown_files pipeline

Dir.glob('**/*/').each do |dir|
  puts "Compiling #{dir.to_s}..."
  Dir.chdir(basedir + '/doc')
  Dir.chdir(dir)

  compile_all_markdown_files pipeline
end

puts 'Done! Your HTML documentation is now in `/doc`.'.green
