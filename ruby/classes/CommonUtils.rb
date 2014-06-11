require 'fileutils'
require 'shellwords'

class CommonUtils
	def print_banner(message)
		puts "------------------------------------------------------"
		puts "#{message}"
		puts "------------------------------------------------------"
		puts ""
	end

	def bash(command)
	  escaped_command = Shellwords.escape(command)
	  IO.popen "bash -c #{escaped_command}" do |fd|
		  until fd.eof?
		    puts fd.readline
		  end
		end
	end
end
