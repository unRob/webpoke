class Webpoke::Config
  
  mark_accessible :base, :headers, :parse, :on_failure, :beforeSend, :format
  
  @@valid_parse_types = ['json']
  
  def initialize(&block)
    @base = '';
    @headers = {}
    @parse = {input:nil, output:nil}
    
    if (block_given?)
      instance_eval(&block);
    end
    
    @format = @format || 'stdout'
    
  end
  
  def on_failure(&block)
    if (block_given?)
      @on_failure = block
    else
      @on_failure
    end
  end
  
  def beforeSend callable=nil
    if callable
      raise new Webpoke::ConfigError("Can't register your beforeSend callable because, well, it isn't callable") if !callable.respond_to? :call
      @beforeSend = callable
    else 
      @beforeSend
    end
  end
  
  def parse type=nil
    if (type)
      case type
      when String
        raise new Webpoke::ConfigError("I don't know how to parse [#{type}] responses yet :/") unless @@valid_parse_types.include? type
        @parse = {
          output: lambda {|d| JSON.parse(d, symbolize_names: true)},
          input: lambda {|d| d.to_json }
        }
      when Hash      
        @parse = type
      end
    else
      @parse
    end
    
  end
    
  
end

class Webpoke::ConfigError < StandardError
end