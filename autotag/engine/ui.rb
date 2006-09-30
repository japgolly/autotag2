require 'autotag/app_info'

module Autotag
  class Engine
    class UI
      
      def initialize(engine)
        @engine= engine
      end
      
      def init
        puts "Golly's MP3 Auto-tagger v#{Autotag::VERSION}"
        puts "Copyright (c) 2006 David Barri. All rights reserved."
        @stats= []
        @all_files= {}
        @artist_id= 0
        @album_id= 0
      end
      
      def on_event(event,*a)
        case event
        # === ROOT ===
        when :root_dir_enter
          @root_dir= a[0]
          @root_dir_len= (@root_dir.gsub(/[\/\\]$/,'')).size + 1
          puts "\nEntering root dir: #{a[0]}"
          @all_files[@root_dir]= Dir.glob("#{@root_dir}/**/*").select{|f|File.file?(f)}.map{|f|f[@root_dir_len..-1]}
          
        
        # === ARTIST ===
        when :artist_dir_enter
          puts " Entering artist dir: #{a[0]}"
          @artist_id += 1
          remove_override_files_in_pwd_from_all_files
          
        # === ALBUM ===
        when :album_dir_enter
          puts "  Entering album dir: #{a[0]}"
          @album_id += 1
          @cd_dir= nil
          remove_override_files_in_pwd_from_all_files
        
        when :cd_dir_enter
          @cd_dir= a[0] + '/'
          remove_override_files_in_pwd_from_all_files
          
        # === TRACK ===
        when :track_process
          @stats<< {
            :artist => @artist_id,
            :album => @album_id,
          }
          remove_file_in_pwd_from_all_files a[0]
          put "   #{@cd_dir}#{a[0]}..."
          
        when :track_update
          @stats.last[:result]= :update
          puts 'updated'
          
        when :track_uptodate
          @stats.last[:result]= :uptodate
          puts 'ok'
          
        else
          raise "Unknown event: '#{event}'"
        end
      end
      
      def shutdown
        @all_files.delete_if {|k,v|v.empty?}
        unprocessed_file_count= @all_files.values.inject(0){|sum,v| sum + v.size}
        tracks_total= @stats.size
        albums_total= @stats.map{|i|i[:album]}.uniq.size
        artists_total= @stats.map{|i|i[:artist]}.uniq.size
        tracks_updated= @stats.select{|i|i[:result]==:update}.size
        tracks_uptodate= @stats.select{|i|i[:result]==:uptodate}.size
        
        if unprocessed_file_count > 0
          puts_new_section 'UNPROCESSED FILES'
          @all_files.each {|root,files|
            puts "+ #{root}"
            files.each{|f| puts "  - #{f}"}
          }
        end
        
        puts_new_section 'STATS'
        puts "Total artists: #{artists_total}"
        puts "Total albums: #{albums_total} (#{div albums_total,artists_total} per artist)"
        puts "Total tracks: #{tracks_total} (#{div tracks_total,albums_total} per album)"
        puts "Total tracks updated: #{tracks_updated} (#{percent tracks_updated,tracks_total})"
        puts "Total tracks up-to-date: #{tracks_uptodate} (#{percent tracks_uptodate,tracks_total})"
        puts "Unprocessed files: #{unprocessed_file_count}"
        
        puts
      end
      
      private
      
      def div(a,b)
        return 0 if b == 0
        x= a / b
        return x if x*b == a
        a.to_f / b.to_f
      end
      
      def percent(a,b)
        x= b == 0 ? 0 : div(a*100,b)
        x.is_a?(Float) ? '%.1f%%' % x : "#{x}%"
      end
      
      def puts_new_section(name)
          puts "\n#{name}\n#{'='*name.length}"
      end
      
      def put(a)
        $stdout.write a
        $stdout.flush
      end
      
      def remove_override_files_in_pwd_from_all_files
        @engine.override_file_names.each {|f|remove_file_in_pwd_from_all_files f}
      end
      
      def remove_file_in_pwd_from_all_files(filename)
        @all_files[@root_dir].delete "#{Dir.pwd}/#{filename}"[@root_dir_len..-1]
      end
      
    end # class UI
  end # class Engine
end # module Autotag
