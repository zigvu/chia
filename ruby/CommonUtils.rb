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
	  return `bash -c #{escaped_command}`
	end
end
