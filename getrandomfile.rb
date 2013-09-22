# 
# get-randomfile.rb written by [a1]
# http://github.com/antekone/get-randomfile
#
# The MIT License (MIT)
# 
# Copyright (c) 2013 antekone
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.require 'optparse'

require 'ostruct'
require 'find'

$debug = false

def log(str)
	return if not $debug
	puts("log: #{str}")
end

def parse_options(args)
	options = OpenStruct.new()
	options.dirlist = []
	options.include_subdirs = false
	options.filter_list = []
	options.found_files = []
	options.verbose = false
	opts = OptionParser.new() do |obj|
		obj.on("-d", "--dir directory_name", "Specify the directory for files to be chosen from (can be specified multiple times)") do |v|
			options.dirlist << v
		end

		obj.on("-s", "--subdirs", "Include subdirectories (on/off flag), default OFF") do |v|
			options.include_subdirs = v
		end

		obj.on("-i", "--include REGEXP", "Accept filter, regular expression. Defaults to '.*', if not specified.") do |v|
			options.filter_list << { method: "accept", regexp: v }
		end

		obj.on("-x", "--exclude REGEXP", "Reject filter, regular expression. Defaults to none, if not specified.") do |v|
			options.filter_list << { method: "reject", regexp: v }
		end

		obj.on("-v", "--verbose", "Enable verbose output (for debugging)") do |v|
			options.verbose = true
		end

		# run a program for each file that accepts whenever to include the file or not.
	end

	opts.parse!(args)

	if(options.dirlist.size() == 0)
		puts(opts)
		puts()
		puts("Accept/reject flag are applied in the same order as they were specified in the")
		puts("argument list.")
		return nil
	end

	if(options.filter_list.size() == 0)
		options.filter_list << { method: "accept", regexp: ".*" }
	end

	$debug = true if options.verbose

	options
end

def dump_filter_list(ctx)
	ctx.filter_list.each() do |filter|
		log(filter.inspect())
	end
end

def dump_found_files(ctx)
	ctx.found_files.each() do |file|
		log("Found file: #{file}")
	end
end

def dump_random_file(ctx)
	arr = ctx.found_files
	n = arr.size()
	
	puts("#{arr[Random.rand(n)]}")
end

def do_main(ctx)
	ctx.dirlist.each() do |dir|
		do_main_fordir(ctx, dir)
	end
end

def do_result(ctx)
	if(ctx.found_files.size() == 0)
		puts("no-files")
		return
	end

	dump_found_files(ctx)
	dump_random_file(ctx)
end

def apply_filters(ctx, f)
	ctx.filter_list.each() do |filter|
		m = filter[:method]
		re = Regexp.new(filter[:regexp])
		matches = f =~ re

		if(m == 'accept')
			return if not matches
		elsif(m == 'reject')
			return if matches
		else
			next
		end
	end

	true
end

def do_main_fordir(ctx, dir)
	Find.find(dir) do |f|
		ldir = File.dirname(f)
		next if(not ctx.include_subdirs and dir != ldir)
		next if(File.directory?(f))

		ctx.found_files << f if(apply_filters(ctx, f))
	end
end

def main(args)
	ctx = parse_options(args)
	return 1 unless(ctx != nil)

	dump_filter_list(ctx)

	do_main(ctx)
	do_result(ctx)

	return 0
end

exit(main($*))
