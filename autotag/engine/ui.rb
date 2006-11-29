require 'autotag/app_info'
require 'autotag/utils'
require 'iconv'

module Autotag
  class Engine
    class UI
      
      def initialize(engine)
        @engine= engine
      end
      
      def init(quiet_mode)
        @quiet_mode= quiet_mode
        puts Autotag::TITLE_AND_VERSION
        puts "Copyright (c) 2006 David Barri. All rights reserved."
        @stats= []
        @all_files= {}
        @artist_id= 0
        @album_id= 0
        @start_time= Time.now
        @screen_charset= Utils.get_system_charset(:console_output)
        @u2s_iconv= Iconv.new(@screen_charset, 'utf-8') if @screen_charset
      end
      
      def on_event(event,*a)
        case event
        # === ROOT ===
        when :root_dir_enter
          actual_root_dir, root_dir_after_globbing = a
          @root_dir= root_dir_after_globbing
          @root_dir_len= (@root_dir.gsub(/[\/\\]$/,'')).size + 1
          puts "\nEntering root dir: #{actual_root_dir}"
          
          # Make a list of all files in the dir tree
          @all_files[@root_dir]= UnicodeIO.glob(-1,@root_dir).select{|f|UnicodeIO.file?(f)}.map{|f|f[@root_dir_len..-1]}
          tmp= '/'+@engine.temp_filename
          tmprange= -tmp.length..-1
          @all_files[@root_dir].delete_if{|f|
            if f[tmprange] == tmp
              true
            elsif @engine.override_file_names.include?(File.basename(f))
              false
            else
              del= false
              @engine.useless_file_patterns.each {|p| (del= true;break) if f =~ p}
              del
            end
          }
        
        # === ARTIST ===
        when :artist_dir_enter
          puts "  Entering artist dir: #{a[0]}"
          @artist_id += 1
          remove_override_files_in_pwd_from_all_files
        
        # === ALBUM ===
        when :album_type_dir_enter
          remove_override_files_in_pwd_from_all_files
          
        when :album_dir_enter
          puts "    Entering album dir: #{a[0]}"
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
            :size => a[1].size,
          }
          track_filename= "#{@cd_dir}#{a[0]}"
          remove_file_in_pwd_from_all_files a[0]
          put "      #{track_filename}..."
          
        when :track_updated
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
        @total_time= Time.now-@start_time
        total_time_str= @total_time>60 ? "#{@total_time.to_i/60}m#{@total_time.to_i%60}s" : "#{@total_time}s"
        
        @all_files.delete_if {|k,v|v.empty?}
        @unprocessed_file_count= @all_files.values.inject(0){|sum,v| sum + v.size}
        
        @total_track_count= @stats.size
        @total_album_count= @stats.map{|i|i[:album]}.uniq.size
        @total_artist_count= @stats.map{|i|i[:artist]}.uniq.size
        
        @updated_track_stats=  @stats.select{|i|i[:result]==:update}
        @uptodate_track_stats= @stats.select{|i|i[:result]==:uptodate}
        @updated_track_count=  @updated_track_stats.size
        @uptodate_track_count= @uptodate_track_stats.size
        @updated_track_size=   @updated_track_stats.inject(0){|sum,v| sum + v[:size]}
        @uptodate_track_size=  @uptodate_track_stats.inject(0){|sum,v| sum + v[:size]}
        @total_file_size=      @updated_track_size + @uptodate_track_size
        
        if @updated_track_size>1 and @total_time>2
          @speed= @updated_track_size.to_f / @total_time.to_f
          speed_str= "#{div @speed,1000000,2} MB/sec"
        end
        
        # Display unprocessed files
        if @unprocessed_file_count > 0
          puts_new_section 'UNPROCESSED FILES'
          @all_files.each {|root,files|
            puts "+ #{root}"
            files.each{|f| puts "  - #{f}"}
          }
        end
        
        # Display stats
        puts_new_section 'STATS'
        puts "Total artists: #{@total_artist_count}"
        puts "Total albums: #{@total_album_count} (#{div @total_album_count,@total_artist_count} per artist)"
        puts "Total tracks: #{@total_track_count} (#{div @total_track_count,@total_album_count} per album)"
        puts " Total tracks updated: #{@updated_track_count} (#{percent @updated_track_count,@total_track_count})"
        puts " Total tracks up-to-date: #{@uptodate_track_count} (#{percent @uptodate_track_count,@total_track_count})"
        puts "Size of all tracks: #{bytes @total_file_size}"
        puts " Size of updated tracks: #{bytes @updated_track_size}"
        puts " Size of up-to-date tracks: #{bytes @uptodate_track_size}"
        puts "Unprocessed files: #{@unprocessed_file_count}"
        puts "Completed in: #{total_time_str}" + (speed_str ? " (#{speed_str})" : '')
        
        puts
      end
      
      #------------------------------------------------------------------------
      private
      
      def bytes(b)
        "#{b.to_i.to_s.gsub(/(\d)(?=\d{3}+$)/, '\1,')} bytes"
      end
      
      def div(a,b,dec=1)
        return '0' if b == 0
        x= (a / b).to_i
        return x.to_s if x * b == a
        "%.#{dec}f" % (a.to_f / b.to_f)
      end
      
      def percent(a,b)
        "#{b == 0 ? 0 : div(a*100,b)}%"
      end
      
      def puts_new_section(name)
          puts "\n#{name}\n#{'='*name.length}"
      end
      
      def put(a)
        return if quiet_mode
        a= safe_convert_u2s(a) if @u2s_iconv
        $stdout.write a
        $stdout.flush
      end
      
      def puts(*a)
        return if quiet_mode
        a= a.map{|s| safe_convert_u2s(s)} if @u2s_iconv
        $stdout.puts(*a)
        $stdout.flush
      end
      
      def quiet_mode
        @quiet_mode
      end
      
      def remove_override_files_in_pwd_from_all_files
        @engine.override_file_names.each {|f|remove_file_in_pwd_from_all_files f}
      end
      
      def remove_file_in_pwd_from_all_files(filename)
        @all_files[@root_dir].delete "#{UnicodeIO.pwd}/#{filename}"[@root_dir_len..-1]
      end
      
      def safe_convert_u2s(str)
        @u2s_iconv.iconv(str)
      rescue Iconv::IllegalSequence
        str.gsub /[^ -~]/, '?'
      end
      
    end # class UI
  end # class Engine
end # module Autotag
