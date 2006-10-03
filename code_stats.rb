require 'autotag/app_info'
puts "Stats for #{Autotag::TITLE_AND_VERSION}\n\n"

def pad(str,size) str + ' '*(size-str.length) end
def padn(num,size) ' '*(size-num.to_s.length) + num.to_s end

files= Dir.glob('**/*.rb') - [__FILE__] - Dir.glob('test/**/*')
stats= files.map{|f| [f,File.read(f).split(/[\r\n]+/).length,File.size(f)]}
max_filename_len= files.inject(0){|max,f| f.length > max ? f.length : max}
total_lines= total_bytes= 0

puts "#{pad 'FILENAME', max_filename_len} #{padn 'LOC',5} #{padn 'BYTES',8}"
puts line= '-'*(max_filename_len+15)
stats.sort.each {|f,lines,bytes|
	puts "#{pad f, max_filename_len} #{padn lines,5} #{padn bytes,8}"
	total_lines += lines
	total_bytes += bytes
}
puts line
puts "#{pad 'TOTAL:', max_filename_len} #{padn total_lines,5} #{padn total_bytes,8}"
