#!/usr/bin/env ruby
#encoding: utf-8
#
#
# License
#
# DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE Version 2, December 2004
# 
# (C) 2012 Roberto Hidalgo un@rob.mx
# 
# Everyone is permitted to copy and distribute verbatim or modified copies of this license document, and changing it is allowed as long as the name is changed.
# 
# DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION
# 
# You just DO WHAT THE FUCK YOU WANT TO.


class String
  
  def red
    "\033[41m\033[37m#{self}\033[0m"
  end
  
  def green
    "\033[42m\033[37m#{self}\033[0m"
  end
  
  def bold
    "\033[1m#{self}\033[0m";
  end
  
end

module Webpoke
  
  require 'httparty'
  require 'Webpoke/Class'
  require 'Webpoke/Config'
  require 'Webpoke/Test'
  
  $successes = 0;
  $errors = 0;
  $tested = 0;
  $tests = [];
  $log = ""
  $config = nil
  
  
=begin rdoc
  Add a test to the queue
  
==== Arguments
  * +block+ The block for configurating this test
=end
  def test(&block)
    $tests << Test.new(&block)
  end
  
  
  def args_for_test(test)
      
    if (!$config)
      $config = Webpoke::Config.new
    end
            
    args = {
      headers: $config.headers.merge(test.headers),
    }
    
    if test.data
      if $config.parse[:input]
        args[:body] = config.parse[:input].call(test.data)
      else
        args[:data] = test.data
      end
    end
    
    args[:query] = test.query if test.query
    
    args
  end
  
  
  def config (&block)
    $config = Webpoke::Config.new(&block)
  end

  
  def run (group=nil)
    
    $tests.each do |test|
      return if group && !test.group == group
      $tested +=1
      
      fqu = if test.url.match(/^https?:\/\//i) then url; else $config.base+test.url; end
      
      args = args_for_test(test)
      
      $config.beforeSend(test.method, fqu, args) if $config.beforeSend
      
      log "#{$tested}: #{test.description}".bold
      log "#{test.method.upcase}: #{test.url}...", false
      begin
        r = HTTParty.send(test.method, fqu, args)
      rescue Exception => e
        log 'FAIL:'.red
        log e
        $errors += 1;
        next;
      end
            
      begin
        body = $config.parse[:ouput] ? $config.parse[:output].call(r.body) : r.body
      rescue Exception => e
        log "Parsing failure: ".red
        log "\t#{e}"
        log "Data:"
        log "\t"+r.body
        $errors += 1;
        next;
      end
      
      if test.passed?(r.code, body)
        $successes +=1
        log "OK!".green
      else
        log "FAIL!".red
                
        if $config.on_failure
          log $config.on_failure.call(r.code, body)
        end
      end
    end
      
  end
  
  
  def log (message, newLine=true)
    return true if $config.format != 'stdout'
    $stdout << message
    $stdout << "\n" if newLine
  end
  
  def Webpoke.document(group)
    
    data = []
    
    $tests.each do |test|
      return if group && !test.group.include?(group)
      
      data << test.describe
      
    end
    
  end
  
  def Webpoke.success
    return $successes
  end
  
  def Webpoke.failed
    return $errors
  end
  
  def Webpoke.tested
    return $tested
  end
  
  def Webpoke.formats
    return ['json', 'html', 'stdout']
  end
  
end