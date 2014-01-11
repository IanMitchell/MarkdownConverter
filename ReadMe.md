# Markdown to HTML

A quick script to convert a directory of Markdown to HTML. Requires the `html-pipeline` and `github-markdown` gems.

## How it Works

The script will go through the `src` directory and verify all the links work correctly (they should be relative. The assumption is that the `src` directory is something like documentation / requirements). It will then convert the Markdown files to their HTML equivalents, putting them in the `doc` folder. 

Each time the script runs, everything in the `doc` folder is deleted and recreated.

## Example Usage

The `src` directory in the repository has been compiled to the `doc` directory, with the following output:

	ianmitchell@~/code/MarkdownConverter$ ruby compile.rb
	Checking for invalid links...
		There is a broken link in table.md: "contents.md"
	Changing to milestones/...
	Changing to tools/...
	Done!
	
	There were errors when checking the links; continue anyways? (y/n) y
	Compiling milestones/...
	Compiling tools/...
	Done! Your HTML documentation is now in `/doc`.