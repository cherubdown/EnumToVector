def usage
	puts "--------------------------------------------------------------------------"
	puts "This small app transforms C/C++ enums into vectors, so that you may"
	puts "iterate over them, and do whatever else you'd want to do with a vector."
	puts ""
	puts "The first arg is the name of the output directory. The remaining variable-"
	puts "length args are files you want transformed."
	puts "--------------------------------------------------------------------------"
	exit
end


def run(outputDir, *inputFiles)
	outDir = ""
	outputFile = ""
	if (outputDir!=nil)
		outDir = outputDir.to_s
		outFileName = ARGV[1]
		outputFile = "#{outDir}/#{File.basename(outFileName, ".*")}_as_vector.h"
	else
		outFileName = ARGV[0]
		outputFile = "#{File.basename(outFileName, ".*")}_as_vector.h"
	end


	allFileContents = []
	inputFiles.each do |inputFile|
		fileContents = File.read(inputFile.to_s)
		fileContents = fileContents.gsub(/(\/\*.*?\*\/)/m, "")
		fileContents.each_line do |line|
			allFileContents.push(line)
		end
	end
	
	#begin parsing logic and writing
	enumBlocks = parseEnumsOut(allFileContents)
	writeFile(outputFile, enumBlocks, inputFiles)
end


def writeFile(outputFile, enumBlocks, inputFiles)
	if (File.exists?(outputFile))
		File.delete(outputFile)
	end
	className = "#{File.basename(outputFile, ".*")}"
	File.open(outputFile, 'w') { |f|
		f << "#ifndef #{className.upcase}\n"
		f << "#define #{className.upcase}\n\n"
		f << "#include <vector>\n"
		inputFiles.each do |includes|
			f << "#include \"#{File.basename(includes.to_s, "")}\"\n"
		end
		f << "\nclass #{className} {\n"
		f << "public:\n"
		f << "  #{className}();\n"
		enumBlocks.keys.each do |enumName|
			f << "  vector<#{enumName}> #{enumName}_vec;\n"
		end
		f << "};\n\n"
		f << "#{className}::#{className}() {\n"
		enumBlocks.each do |key, values|
			f << "  // #{key} values\n"
			values.each do |value|
				f << "  #{key}_vec.push_back(#{value});\n"
			end
		end
		f << "}\n\n"
		f << "#endif"
	}
end


def parseEnumsOut(contents)
	enumBlocks = {}
	state = nil
	block = []
	key = ""
	contents.each do |line|
		case(state)
		when nil
			#look for line with 'typedef enum'
			if(line.match("typedef enum"))
				state = :sources
			end
		when :sources
			if(line.match(/\}*;/))
				state = nil
				enumBlocks[line.gsub(/[\} ;\n]/, "")] = block;
				block = []
			else
				#remove the empty lines
				if (line.strip.length != 0)
					block.push(line.gsub(/[\n\s,]/, "").gsub(/=\d*/, ""))
				end
			end
		end
	end
	return enumBlocks
end


### MAIN
#check for bad input
if (ARGV[0] != nil && ARGV[1] == nil)
	run(nil, ARGV[0])
	exit
end
outputDir = ARGV[0] #from here on, we know there are at least 2 args.
inputFiles = []
ARGV.each do |arg|
	if(ARGV[0] != arg)
		inputFiles.push(arg)
	end
end


run(outputDir, inputFiles)
